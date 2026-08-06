# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Coupons::Statuses do
  describe ".values" do
    it "returns all valid statuses" do
      expect(described_class.values).to contain_exactly("ACTIVE", "INACTIVE", "EXPIRED", "DISABLED")
    end
  end

  describe ".valid?" do
    it("returns true for ACTIVE") { expect(described_class.valid?("ACTIVE")).to be true }
    it("returns false for PENDING") { expect(described_class.valid?("PENDING")).to be false }
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("ACTIVE")).to eq("ACTIVE")
    end

    it "raises ArgumentError for an invalid status" do
      expect { described_class.validate!("UNKNOWN") }.to raise_error(ArgumentError)
    end
  end
end
