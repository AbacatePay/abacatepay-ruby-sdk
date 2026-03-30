# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::StoreClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#get" do
    before do
      stubs.get("/v1/store/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "store-1", "name" => "My Store",
                        "balance" => { "available" => 10000, "pending" => 500, "blocked" => 0 } } }.to_json]
      end
    end

    it "returns a Store resource" do
      result = client.get
      expect(result).to be_a(AbacatePay::Resources::Store)
      expect(result.name).to eq("My Store")
    end

    it "maps balance correctly" do
      result = client.get
      expect(result.balance).to be_a(AbacatePay::Resources::Store::Balance)
      expect(result.balance.available).to eq(10000)
      expect(result.balance.pending).to eq(500)
      expect(result.balance.blocked).to eq(0)
    end
  end

  describe "#merchant_info" do
    before do
      stubs.get("/v1/public-mrr/merchant-info") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "name" => "My Store" } }.to_json]
      end
    end

    it "returns merchant info data" do
      result = client.merchant_info
      expect(result).to be_a(Hash)
      expect(result["name"]).to eq("My Store")
    end
  end

  describe "#mrr" do
    before do
      stubs.get("/v1/public-mrr/mrr") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "mrr" => 50000 } }.to_json]
      end
    end

    it "returns MRR data" do
      result = client.mrr
      expect(result).to be_a(Hash)
    end
  end

  describe "#revenue" do
    before do
      stubs.get("/v1/public-mrr/revenue") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "total" => 100000 } }.to_json]
      end
    end

    it "returns revenue data" do
      result = client.revenue(start_date: "2026-01-01", end_date: "2026-03-30")
      expect(result).to be_a(Hash)
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v1/store/get") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.get }.to raise_error(AbacatePay::ApiError)
    end
  end
end
