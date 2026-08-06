# frozen_string_literal: true

require "stringio"

RSpec.describe AbacatePay::Resources::Coupons do
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
      let(:coupon) do
        described_class.new({
                              "id" => "coup-1",
                              "code" => "SAVE20",
                              "discount" => 20,
                              "discountKind" => "PERCENTAGE",
                              "maxRedeems" => 100,
                              "currentRedeems" => 5,
                              "status" => "ACTIVE",
                              "createdAt" => "2026-01-15T10:00:00Z"
                            })
      end

      it("sets id") { expect(coupon.id).to eq("coup-1") }
      it("sets code") { expect(coupon.code).to eq("SAVE20") }
      it("sets discount") { expect(coupon.discount).to eq(20) }
      it("sets discount_kind") { expect(coupon.discount_kind).to eq("PERCENTAGE") }
      it("sets max_redeems") { expect(coupon.max_redeems).to eq(100) }
      it("sets current_redeems") { expect(coupon.current_redeems).to eq(5) }
      it("sets status") { expect(coupon.status).to eq("ACTIVE") }
      it("parses created_at") { expect(coupon.created_at).to be_a(DateTime) }
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        coupon = described_class.new({})
        expect(coupon.id).to be_nil
        expect(coupon.code).to be_nil
      end
    end

    context "with a status the SDK does not know" do
      it "passes it through instead of raising" do
        expect { silence_stderr { described_class.new({ "status" => "INVALID" }) } }.not_to raise_error
      end

      it "keeps the value the API sent" do
        coupon = nil
        silence_stderr { coupon = described_class.new({ "status" => "INVALID" }) }
        expect(coupon.status).to eq("INVALID")
      end
    end
  end
end
