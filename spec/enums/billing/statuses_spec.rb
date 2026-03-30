# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Billings::Statuses do
  describe ".values" do
    it "returns all valid statuses" do
      expect(described_class.values).to contain_exactly("PENDING", "EXPIRED", "CANCELLED", "PAID", "REFUNDED")
    end

    it "returns an Array" do
      expect(described_class.values).to be_an(Array)
    end
  end

  describe ".valid?" do
    it "returns true for PENDING" do
      expect(described_class.valid?("PENDING")).to be true
    end

    it "returns true for EXPIRED" do
      expect(described_class.valid?("EXPIRED")).to be true
    end

    it "returns true for CANCELLED" do
      expect(described_class.valid?("CANCELLED")).to be true
    end

    it "returns true for PAID" do
      expect(described_class.valid?("PAID")).to be true
    end

    it "returns true for REFUNDED" do
      expect(described_class.valid?("REFUNDED")).to be true
    end

    it "returns false for an unknown status" do
      expect(described_class.valid?("UNKNOWN")).to be false
    end

    it "returns false for a lowercase value" do
      expect(described_class.valid?("pending")).to be false
    end

    it "returns false for an empty string" do
      expect(described_class.valid?("")).to be false
    end
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("PENDING")).to eq("PENDING")
    end

    it "returns the value for every valid status" do
      described_class.values.each do |status|
        expect(described_class.validate!(status)).to eq(status)
      end
    end

    it "raises ArgumentError for an invalid status" do
      expect { described_class.validate!("INVALID") }
        .to raise_error(ArgumentError, /Invalid status/)
    end

    it "raises ArgumentError for an empty string" do
      expect { described_class.validate!("") }
        .to raise_error(ArgumentError)
    end
  end
end
