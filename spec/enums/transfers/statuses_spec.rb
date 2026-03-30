# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Transfers::Statuses do
  describe ".values" do
    it "returns all valid statuses" do
      expect(described_class.values).to contain_exactly(
        "PENDING", "COMPLETE", "CANCELLED", "EXPIRED", "REFUNDED", "FAILED"
      )
    end
  end

  describe ".valid?" do
    it("returns true for FAILED") { expect(described_class.valid?("FAILED")).to be true }
    it("returns true for COMPLETE") { expect(described_class.valid?("COMPLETE")).to be true }
    it("returns false for PAID") { expect(described_class.valid?("PAID")).to be false }
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
