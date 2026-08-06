# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Checkouts::Statuses do
  describe ".values" do
    it "returns all valid statuses" do
      expect(described_class.values).to contain_exactly(
        "PENDING", "EXPIRED", "CANCELLED", "PAID", "REFUNDED", "ACTIVE"
      )
    end
  end

  describe ".valid?" do
    it("returns true for PAID") { expect(described_class.valid?("PAID")).to be true }
    it("returns false for UNKNOWN") { expect(described_class.valid?("UNKNOWN")).to be false }
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("PENDING")).to eq("PENDING")
    end

    it "raises ArgumentError for an invalid status" do
      expect { described_class.validate!("INVALID") }.to raise_error(ArgumentError)
    end
  end
end
