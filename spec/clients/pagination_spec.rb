# frozen_string_literal: true

# List endpoints cap at 100 items and report whether more exist. The SDK used
# to discard that metadata, so there was no way to reach record 101.
RSpec.describe "List pagination" do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/customers/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { AbacatePay::Clients::CustomerClient.new(faraday_client) }

  def page(ids, has_more:, next_cursor: nil)
    [200, { "Content-Type" => "application/json" },
     { "data" => ids.map { |id| { "id" => id } },
       "pagination" => { "hasMore" => has_more, "next" => next_cursor } }.to_json]
  end

  describe "a single page" do
    before { stubs.get("/v2/customers/list") { page(%w[c1 c2], has_more: true, next_cursor: "c2") } }

    it "returns a Collection" do
      expect(client.list).to be_a(AbacatePay::Collection)
    end

    it "maps items into resources" do
      expect(client.list.first).to be_a(AbacatePay::Resources::Customers)
    end

    it "preserves hasMore through the mapping" do
      expect(client.list.has_more?).to be true
    end

    it "preserves the cursor through the mapping" do
      expect(client.list.next_cursor).to eq("c2")
    end
  end

  describe "a response without pagination metadata" do
    before do
      stubs.get("/v2/customers/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => [{ "id" => "c1" }] }.to_json]
      end
    end

    # Endpoints that do not paginate must keep returning a plain Array.
    it "returns a plain Array" do
      expect(client.list).to be_an(Array)
    end
  end

  describe "#each_page" do
    before do
      responses = [
        page(%w[c1 c2], has_more: true, next_cursor: "c2"),
        page(%w[c3], has_more: false)
      ]
      stubs.get("/v2/customers/list") { responses.shift }
    end

    it "yields every page in order" do
      pages = []
      client.each_page { |p| pages << p.map(&:id) }

      expect(pages).to eq([%w[c1 c2], %w[c3]])
    end

    it "stops when hasMore turns false" do
      count = 0
      client.each_page { |_p| count += 1 }

      expect(count).to eq(2)
    end
  end

  describe "#auto_paging_each" do
    before do
      responses = [
        page(%w[c1 c2], has_more: true, next_cursor: "c2"),
        page(%w[c3], has_more: false)
      ]
      stubs.get("/v2/customers/list") { responses.shift }
    end

    it "yields every record across pages" do
      ids = []
      client.auto_paging_each { |customer| ids << customer.id }

      expect(ids).to eq(%w[c1 c2 c3])
    end

    it "returns an Enumerator without a block" do
      expect(client.auto_paging_each).to be_a(Enumerator)
    end
  end

  describe "a page that claims hasMore but sends no cursor" do
    before { stubs.get("/v2/customers/list") { page(%w[c1], has_more: true, next_cursor: nil) } }

    # Without this guard the loop would refetch page one forever.
    it "stops instead of looping" do
      count = 0
      client.each_page { |_p| count += 1 }

      expect(count).to eq(1)
    end
  end
end
