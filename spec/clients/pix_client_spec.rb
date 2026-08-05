# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::PixClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/pix/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v2/pix/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "pix-1", "amount" => 1000, "status" => "COMPLETE" }] }.to_json]
      end
    end

    it "returns an Array of PixTransfers" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::PixTransfers)
    end
  end

  describe "#get" do
    before do
      stubs.get("/v2/pix/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "pix-1", "amount" => 1000 } }.to_json]
      end
    end

    it "returns a PixTransfers resource" do
      result = client.get("pix-1")
      expect(result).to be_a(AbacatePay::Resources::PixTransfers)
      expect(result.amount).to eq(1000)
    end
  end

  describe "#send_pix" do
    before do
      stubs.post("/v2/pix/send") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "pix-new", "status" => "PENDING" } }.to_json]
      end
    end

    it "returns a PixTransfers resource" do
      attributes = { "amount" => 500, "externalId" => "ext-1", "key" => "12345678900", "keyType" => "CPF" }
      transfer = AbacatePay::Resources::PixTransfers.new(attributes)
      result = client.send_pix(transfer)
      expect(result).to be_a(AbacatePay::Resources::PixTransfers)
      expect(result.id).to eq("pix-new")
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v2/pix/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end
end
