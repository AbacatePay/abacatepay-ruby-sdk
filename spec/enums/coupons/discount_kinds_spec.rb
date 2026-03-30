# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Coupons::DiscountKinds do
  describe ".values" do
    it "returns all valid discount kinds" do
      expect(described_class.values).to contain_exactly("PERCENTAGE", "FIXED")
    end
  end

  describe ".valid?" do
    it("returns true for PERCENTAGE") { expect(described_class.valid?("PERCENTAGE")).to be true }
    it("returns true for FIXED") { expect(described_class.valid?("FIXED")).to be true }
    it("returns false for AMOUNT") { expect(described_class.valid?("AMOUNT")).to be false }
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("FIXED")).to eq("FIXED")
    end

    it "raises ArgumentError for an invalid kind" do
      expect { described_class.validate!("AMOUNT") }.to raise_error(ArgumentError)
    end
  end
end
