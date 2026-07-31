# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::TransparentClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/transparents/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v1/transparents/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "tr-1", "amount" => 500 }] }.to_json]
      end
    end

    it "returns an Array of Transparents" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::Transparents)
    end
  end

  describe "#create" do
    before do
      stubs.post("/v1/transparents/create") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "tr-new", "qrCode" => "00020126..." } }.to_json]
      end
    end

    it "returns a Transparents resource" do
      transparent = AbacatePay::Resources::Transparents.new({ "amount" => 1000 })
      result = client.create(transparent)
      expect(result).to be_a(AbacatePay::Resources::Transparents)
      expect(result.qr_code).to eq("00020126...")
    end
  end

  describe "#check" do
    before do
      stubs.get("/v1/transparents/check") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "tr-1", "status" => "PAID" } }.to_json]
      end
    end

    it "returns a Transparents resource" do
      result = client.check("tr-1")
      expect(result).to be_a(AbacatePay::Resources::Transparents)
      expect(result.status).to eq("PAID")
    end
  end

  describe "#simulate_payment" do
    before do
      stubs.post("/v1/transparents/simulate-payment?id=tr-1") do |env|
        expect(env.params["id"]).to eq("tr-1")
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "tr-1", "status" => "PAID" } }.to_json]
      end
    end

    it "sends the id as a query param and returns a Transparents resource" do
      result = client.simulate_payment("tr-1")
      expect(result).to be_a(AbacatePay::Resources::Transparents)
      expect(result.status).to eq("PAID")
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v1/transparents/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end
end
