# frozen_string_literal: true

require "stringio"

RSpec.describe AbacatePay::Resources::Payouts do
  # Unknown enum values pass through with a warning instead of raising, so the
  # SDK does not break when AbacatePay introduces a value.
  def silence_stderr
    original = $stderr
    $stderr = StringIO.new
    yield
    $stderr.string
  ensure
    $stderr = original
  end
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

    context "with a status the SDK does not know" do
      it "passes it through instead of raising" do
        expect { silence_stderr { described_class.new({ "status" => "INVALID" }) } }.not_to raise_error
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
