# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::CheckoutClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/checkouts/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v1/checkouts/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "chk-1", "amount" => 1000, "status" => "PAID" }] }.to_json]
      end
    end

    it "returns an Array of Checkouts" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::Checkouts)
    end

    it "maps checkout attributes" do
      expect(client.list.first.amount).to eq(1000)
    end
  end

  describe "#get" do
    before do
      stubs.get("/v1/checkouts/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "chk-1", "url" => "https://pay.abacatepay.com/chk-1" } }.to_json]
      end
    end

    it "returns a Checkouts resource" do
      result = client.get("chk-1")
      expect(result).to be_a(AbacatePay::Resources::Checkouts)
      expect(result.url).to eq("https://pay.abacatepay.com/chk-1")
    end
  end

  describe "#create" do
    before do
      stubs.post("/v1/checkouts/create") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "chk-new", "amount" => 5000, "url" => "https://pay.abacatepay.com/chk-new" } }.to_json]
      end
    end

    it "with customer ID returns a Checkouts resource" do
      checkout = AbacatePay::Resources::Checkouts.new({
        "frequency" => "ONE_TIME",
        "methods" => ["PIX"]
      })
      checkout.instance_variable_set(:@products, [
        AbacatePay::Resources::Billings::Product.new({
          "externalId" => "prod-1", "name" => "Item", "price" => 5000, "quantity" => 1
        })
      ])
      customer = AbacatePay::Resources::Customers.new({ "id" => "cust-1" })
      checkout.instance_variable_set(:@customer, customer)

      result = client.create(checkout)
      expect(result).to be_a(AbacatePay::Resources::Checkouts)
      expect(result.id).to eq("chk-new")
    end

    it "with inline customer returns a Checkouts resource" do
      checkout = AbacatePay::Resources::Checkouts.new({
        "frequency" => "ONE_TIME",
        "methods" => ["PIX"]
      })
      customer = AbacatePay::Resources::Customers.new({})
      metadata = AbacatePay::Resources::Customers::Metadata.new({})
      metadata.name = "John"
      metadata.email = "john@example.com"
      customer.instance_variable_set(:@metadata, metadata)
      checkout.instance_variable_set(:@customer, customer)

      result = client.create(checkout)
      expect(result).to be_a(AbacatePay::Resources::Checkouts)
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v1/checkouts/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end
end
