# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Subscriptions do
  describe "#initialize" do
    context "with API data" do
      let(:subscription) do
        described_class.new({
          "id" => "sub-1",
          "url" => "https://pay.abacatepay.com/sub-1",
          "status" => "PAID",
          "devMode" => false,
          "methods" => ["PIX"],
          "externalId" => "ext-1",
          "createdAt" => "2026-01-15T10:00:00Z",
          "customer" => { "id" => "cust-1" },
          "products" => [{ "externalId" => "prod-1", "name" => "Monthly Plan", "price" => 2990 }]
        })
      end

      it("sets id") { expect(subscription.id).to eq("sub-1") }
      it("sets status") { expect(subscription.status).to eq("PAID") }
      it("sets dev_mode?") { expect(subscription.dev_mode?).to be false }
      it("sets methods") { expect(subscription.methods).to eq(["PIX"]) }
      it("sets customer") { expect(subscription.customer).to be_a(AbacatePay::Resources::Customers) }
      it("sets products") { expect(subscription.products).to be_an(Array) }
      it("parses created_at") { expect(subscription.created_at).to be_a(DateTime) }
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        sub = described_class.new({})
        expect(sub.id).to be_nil
      end
    end
  end
end
