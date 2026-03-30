# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Products::Cycles do
  describe ".values" do
    it "returns all valid cycles" do
      expect(described_class.values).to contain_exactly(
        "WEEKLY", "MONTHLY", "SEMIANNUALLY", "ANNUALLY"
      )
    end

    it "returns an Array" do
      expect(described_class.values).to be_an(Array)
    end
  end

  describe ".valid?" do
    it("returns true for WEEKLY") { expect(described_class.valid?("WEEKLY")).to be true }
    it("returns true for MONTHLY") { expect(described_class.valid?("MONTHLY")).to be true }
    it("returns false for ONE_TIME") { expect(described_class.valid?("ONE_TIME")).to be false }
    it("returns false for empty string") { expect(described_class.valid?("")).to be false }
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("MONTHLY")).to eq("MONTHLY")
    end

    it "raises ArgumentError for an invalid cycle" do
      expect { described_class.validate!("DAILY") }.to raise_error(ArgumentError, /Invalid product cycle/)
    end
  end
end
