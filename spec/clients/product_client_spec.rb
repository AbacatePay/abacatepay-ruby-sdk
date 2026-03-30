# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::ProductClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/products/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v1/products/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "prod-1", "name" => "Test" }] }.to_json]
      end
    end

    it "returns an Array of Products" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::Products)
    end

    it "maps product attributes" do
      expect(client.list.first.id).to eq("prod-1")
    end
  end

  describe "#get" do
    before do
      stubs.get("/v1/products/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "prod-1", "name" => "Test Product" } }.to_json]
      end
    end

    it "returns a Products resource" do
      expect(client.get("prod-1")).to be_a(AbacatePay::Resources::Products)
    end

    it "maps the product name" do
      expect(client.get("prod-1").name).to eq("Test Product")
    end
  end

  describe "#create" do
    before do
      stubs.post("/v1/products/create") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "prod-new", "name" => "New Product" } }.to_json]
      end
    end

    it "returns a Products resource" do
      product = AbacatePay::Resources::Products.new({
        "externalId" => "ext-1", "name" => "New Product", "price" => 1000
      })
      result = client.create(product)
      expect(result).to be_a(AbacatePay::Resources::Products)
      expect(result.id).to eq("prod-new")
    end
  end

  describe "#delete" do
    before do
      stubs.post("/v1/products/delete") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "prod-1" } }.to_json]
      end
    end

    it "returns a Products resource" do
      expect(client.delete("prod-1")).to be_a(AbacatePay::Resources::Products)
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v1/products/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end
end
