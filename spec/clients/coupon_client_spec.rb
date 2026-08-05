# frozen_string_literal: true

RSpec.describe AbacatePay::Clients::CouponClient do
  let(:stubs) { Faraday::Adapter::Test::Stubs.new }
  let(:faraday_client) do
    Faraday.new(url: "#{AbacatePay.configuration.api_url}/coupons/") do |f|
      f.adapter :test, stubs
    end
  end
  let(:client) { described_class.new(faraday_client) }

  describe "#list" do
    before do
      stubs.get("/v2/coupons/list") do
        [200, { "Content-Type" => "application/json" },
         { "data" => [{ "id" => "coup-1", "code" => "SAVE10" }] }.to_json]
      end
    end

    it "returns an Array of Coupons" do
      result = client.list
      expect(result).to be_an(Array)
      expect(result.first).to be_a(AbacatePay::Resources::Coupons)
    end

    it "maps coupon attributes" do
      expect(client.list.first.code).to eq("SAVE10")
    end
  end

  describe "#get" do
    before do
      stubs.get("/v2/coupons/get") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "coup-1", "code" => "SAVE10" } }.to_json]
      end
    end

    it "returns a Coupons resource" do
      expect(client.get("coup-1")).to be_a(AbacatePay::Resources::Coupons)
    end
  end

  describe "#create" do
    before do
      stubs.post("/v2/coupons/create") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "coup-new", "code" => "NEW20" } }.to_json]
      end
    end

    it "returns a Coupons resource" do
      coupon = AbacatePay::Resources::Coupons.new({
                                                    "code" => "NEW20", "discount" => 20, "discountKind" => "PERCENTAGE"
                                                  })
      result = client.create(coupon)
      expect(result).to be_a(AbacatePay::Resources::Coupons)
      expect(result.id).to eq("coup-new")
    end
  end

  describe "#delete" do
    before do
      stubs.post("/v2/coupons/delete") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "coup-1" } }.to_json]
      end
    end

    it "returns a Coupons resource" do
      expect(client.delete("coup-1")).to be_a(AbacatePay::Resources::Coupons)
    end
  end

  describe "#toggle" do
    before do
      stubs.post("/v2/coupons/toggle") do
        [200, { "Content-Type" => "application/json" },
         { "data" => { "id" => "coup-1", "status" => "INACTIVE" } }.to_json]
      end
    end

    it "returns a Coupons resource" do
      result = client.toggle("coup-1")
      expect(result).to be_a(AbacatePay::Resources::Coupons)
      expect(result.status).to eq("INACTIVE")
    end
  end

  describe "when the API returns an error" do
    before do
      stubs.get("/v2/coupons/list") { raise Faraday::ConnectionFailed.new("timeout") }
    end

    it "raises ApiError" do
      expect { client.list }.to raise_error(AbacatePay::ApiError)
    end
  end
end
