# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Checkouts do
  describe "#initialize" do
    context "with API data" do
      let(:checkout) do
        described_class.new({
          "id" => "chk-1",
          "url" => "https://pay.abacatepay.com/chk-1",
          "amount" => 5000,
          "status" => "PAID",
          "devMode" => true,
          "methods" => ["PIX", "CARD"],
          "frequency" => "ONE_TIME",
          "externalId" => "ext-1",
          "coupons" => ["SAVE10"],
          "createdAt" => "2026-01-15T10:00:00Z",
          "products" => [{ "externalId" => "prod-1", "name" => "Item", "price" => 5000 }],
          "customer" => { "id" => "cust-1" }
        })
      end

      it("sets id") { expect(checkout.id).to eq("chk-1") }
      it("sets url") { expect(checkout.url).to eq("https://pay.abacatepay.com/chk-1") }
      it("sets amount") { expect(checkout.amount).to eq(5000) }
      it("sets status enum") { expect(checkout.status).to eq("PAID") }
      it("sets dev_mode") { expect(checkout.dev_mode?).to be true }
      it("sets methods array") { expect(checkout.methods).to eq(["PIX", "CARD"]) }
      it("sets frequency") { expect(checkout.frequency).to eq("ONE_TIME") }
      it("sets external_id") { expect(checkout.external_id).to eq("ext-1") }
      it("sets coupons") { expect(checkout.coupons).to eq(["SAVE10"]) }
      it("parses created_at") { expect(checkout.created_at).to be_a(DateTime) }
      it("sets products as array") { expect(checkout.products).to be_an(Array) }
      it("sets customer") { expect(checkout.customer).to be_a(AbacatePay::Resources::Customers) }
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        checkout = described_class.new({})
        expect(checkout.id).to be_nil
        expect(checkout.amount).to be_nil
      end
    end
  end
end
