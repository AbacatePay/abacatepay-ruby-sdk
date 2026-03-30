# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::CustomerClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/customer/") do |f|
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
      stubs.get("/v1/customer/list") do
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
      client.list.each do |customer|
        expect(customer).to be_a(AbacatePay::Resources::Customers)
      end
    end

    it "maps customer id correctly" do
      expect(client.list.first.id).to eq("cust-1")
    end
  end

  describe "#list when the API returns an empty array" do
    before do
      stubs.get("/v1/customer/list") do
        [200, { "Content-Type" => "application/json" }, { "data" => [] }.to_json]
      end
    end

    it "returns an empty array" do
      expect(client.list).to eq([])
    end
  end

  describe "#list when the API returns an error" do
    before do
      stubs.get("/v1/customer/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end

  # ── create ────────────────────────────────────────────────────────────────────

  describe "#create" do
    let(:response_data) { { "id" => "cust-new" } }

    before do
      stubs.post("/v1/customer/create") do
        [200, { "Content-Type" => "application/json" }, { "data" => response_data }.to_json]
      end
    end

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
      stubs.post("/v1/customer/create") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      customer = AbacatePay::Resources::Customers.new({})
      expect { client.create(customer) }.to raise_error(AbacatePay::ApiError)
    end
  end
end
