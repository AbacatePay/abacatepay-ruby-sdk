# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Billings::Frequencies do
  describe ".values" do
    it "returns all valid frequencies" do
      expect(described_class.values).to contain_exactly(
        "ONE_TIME", "WEEKLY", "MONTHLY", "SEMIANNUALLY", "ANNUALLY", "MULTIPLE_PAYMENTS"
      )
    end

    it "returns an Array" do
      expect(described_class.values).to be_an(Array)
    end
  end

  describe ".valid?" do
    it "returns true for ONE_TIME" do
      expect(described_class.valid?("ONE_TIME")).to be true
    end

    it "returns true for MONTHLY" do
      expect(described_class.valid?("MONTHLY")).to be true
    end

    it "returns false for an unsupported frequency" do
      expect(described_class.valid?("DAILY")).to be false
    end

    it "returns false for a lowercase value" do
      expect(described_class.valid?("one_time")).to be false
    end

    it "returns false for an empty string" do
      expect(described_class.valid?("")).to be false
    end
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("ONE_TIME")).to eq("ONE_TIME")
    end

    it "raises ArgumentError for an invalid frequency" do
      expect { described_class.validate!("DAILY") }
        .to raise_error(ArgumentError, /Invalid frequency/)
    end

    it "raises ArgumentError for an empty string" do
      expect { described_class.validate!("") }
        .to raise_error(ArgumentError)
    end
  end
end
