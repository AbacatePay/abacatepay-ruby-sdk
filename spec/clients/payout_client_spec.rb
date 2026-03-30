# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::PayoutClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/payouts/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v1/payouts/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "pay-1", "amount" => 5000, "status" => "COMPLETE" }] }.to_json]
      end
    end

    it "returns an Array of Payouts" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::Payouts)
    end
  end

  describe "#get" do
    before do
      stubs.get("/v1/payouts/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "pay-1", "amount" => 5000 } }.to_json]
      end
    end

    it "returns a Payouts resource" do
      result = client.get("pay-1")
      expect(result).to be_a(AbacatePay::Resources::Payouts)
      expect(result.amount).to eq(5000)
    end
  end

  describe "#create" do
    before do
      stubs.post("/v1/payouts/create") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "pay-new", "status" => "PENDING" } }.to_json]
      end
    end

    it "returns a Payouts resource" do
      payout = AbacatePay::Resources::Payouts.new({
        "amount" => 5000, "externalId" => "ext-1"
      })
      result = client.create(payout)
      expect(result).to be_a(AbacatePay::Resources::Payouts)
      expect(result.id).to eq("pay-new")
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v1/payouts/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end
end
