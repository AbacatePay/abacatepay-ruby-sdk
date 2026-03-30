# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Payouts do
  describe "#initialize" do
    context "with API data" do
      let(:payout) do
        described_class.new({
          "id" => "pay-1",
          "amount" => 5000,
          "externalId" => "ext-1",
          "description" => "Monthly withdrawal",
          "status" => "COMPLETE",
          "createdAt" => "2026-01-15T10:00:00Z"
        })
      end

      it("sets id") { expect(payout.id).to eq("pay-1") }
      it("sets amount") { expect(payout.amount).to eq(5000) }
      it("sets external_id") { expect(payout.external_id).to eq("ext-1") }
      it("sets status enum") { expect(payout.status).to eq("COMPLETE") }
      it("parses created_at") { expect(payout.created_at).to be_a(DateTime) }
    end

    context "with invalid status" do
      it "raises ArgumentError" do
        expect { described_class.new({ "status" => "INVALID" }) }
          .to raise_error(ArgumentError)
      end
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        payout = described_class.new({})
        expect(payout.id).to be_nil
      end
    end
  end
end
