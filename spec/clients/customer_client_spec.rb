# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::CustomerClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/customers/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  # ── list ──────────────────────────────────────────────────────────────────────

  describe "#list" do
    let(:customer_data) do
      [
        { "id" => "cust-1" },
        { "id" => "cust-2" }
      ]
    end

    before do
      stubs.get("/v2/customers/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => customer_data }.to_json]
      end
    end

    it "returns an Array" do
      expect(client.list).to be_an(Array)
    end

    it "returns the correct number of customers" do
      expect(client.list.size).to eq(2)
    end

    it "returns Customers resource instances" do
      expect(client.list).to all(be_a(AbacatePay::Resources::Customers))
    end

    it "maps customer id correctly" do
      expect(client.list.first.id).to eq("cust-1")
    end
  end

  describe "#list when the API returns an empty array" do
    before do
      stubs.get("/v2/customers/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => [] }.to_json]
      end
    end

    it "returns an empty array" do
      expect(client.list).to eq([])
    end
  end

  describe "#list when the API returns an error" do
    before do
      stubs.get("/v2/customers/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end

  # ── create ────────────────────────────────────────────────────────────────────

  describe "#create" do
    let(:response_data) { { "id" => "cust-new" } }
    let(:customer_input) do
      customer = AbacatePay::Resources::Customers.new({})
      metadata = AbacatePay::Resources::Customers::Metadata.new({})
      metadata.name = "Carlos Mendes"
      metadata.email = "carlos@example.com"
      metadata.cellphone = "+5511912340000"
      metadata.tax_id = "000.111.222-33"
      customer.instance_variable_set(:@metadata, metadata)
      customer
    end

    before do
      stubs.post("/v2/customers/create") do
        [200, { "Content-Type" => "application/json" }, { "data" => response_data }.to_json]
      end
    end

    it "returns a Customers resource" do
      expect(client.create(customer_input)).to be_a(AbacatePay::Resources::Customers)
    end

    it "maps the returned customer id" do
      result = client.create(customer_input)
      expect(result.id).to eq("cust-new")
    end
  end

  describe "#create when the API returns an error" do
    before do
      stubs.post("/v2/customers/create") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      customer = AbacatePay::Resources::Customers.new({})
      expect { client.create(customer) }.to raise_error(AbacatePay::ApiError)
    end
  end

  # ── get ───────────────────────────────────────────────────────────────────

  describe "#get" do
    before do
      stubs.get("/v2/customers/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "cust-42", "metadata" => { "name" => "Ana" } } }.to_json]
      end
    end

    it "returns a Customers resource" do
      expect(client.get("cust-42")).to be_a(AbacatePay::Resources::Customers)
    end

    it "maps the customer id" do
      expect(client.get("cust-42").id).to eq("cust-42")
    end

    it "maps nested metadata" do
      expect(client.get("cust-42").metadata.name).to eq("Ana")
    end
  end

  # ── delete ────────────────────────────────────────────────────────────────

  describe "#delete" do
    before do
      stubs.post("/v2/customers/delete") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "cust-42" } }.to_json]
      end
    end

    it "returns a Customers resource" do
      expect(client.delete("cust-42")).to be_a(AbacatePay::Resources::Customers)
    end

    it "maps the deleted customer id" do
      expect(client.delete("cust-42").id).to eq("cust-42")
    end
  end
end
