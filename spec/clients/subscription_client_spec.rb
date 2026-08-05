# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::SubscriptionClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/subscriptions/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v2/subscriptions/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "sub-1", "status" => "PAID" }] }.to_json]
      end
    end

    it "returns an Array of Subscriptions" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::Subscriptions)
    end
  end

  describe "#create" do
    before do
      stubs.post("/v2/subscriptions/create") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "sub-new" } }.to_json]
      end
    end

    it "returns a Subscriptions resource" do
      sub = AbacatePay::Resources::Subscriptions.new({ "methods" => ["PIX"] })
      customer = AbacatePay::Resources::Customers.new({ "id" => "cust-1" })
      sub.instance_variable_set(:@customer, customer)
      attributes = { "externalId" => "prod-1", "name" => "Monthly Plan", "price" => 2990, "quantity" => 1 }
      product = AbacatePay::Resources::Billings::Product.new(attributes)
      sub.instance_variable_set(:@products, [product])

      result = client.create(sub)
      expect(result).to be_a(AbacatePay::Resources::Subscriptions)
      expect(result.id).to eq("sub-new")
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v2/subscriptions/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end

  describe "#cancel" do
    before do
      stubs.post("/v2/subscriptions/cancel") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "subs-1", "status" => "CANCELLED" } }.to_json]
      end
    end

    it "returns the cancelled subscription" do
      expect(client.cancel("subs-1").status).to eq("CANCELLED")
    end
  end
end
