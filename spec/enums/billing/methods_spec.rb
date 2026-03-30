# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Billings::Methods do
  describe ".values" do
    it "returns all valid payment methods" do
      expect(described_class.values).to contain_exactly("PIX", "CARD")
    end

    it "returns an Array" do
      expect(described_class.values).to be_an(Array)
    end
  end

  describe ".valid?" do
    it "returns true for PIX" do
      expect(described_class.valid?("PIX")).to be true
    end

    it "returns false for an unsupported method" do
      expect(described_class.valid?("CREDIT_CARD")).to be false
    end

    it "returns false for a lowercase value" do
      expect(described_class.valid?("pix")).to be false
    end

    it "returns false for an empty string" do
      expect(described_class.valid?("")).to be false
    end
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("PIX")).to eq("PIX")
    end

    it "raises ArgumentError for an invalid method" do
      expect { described_class.validate!("CREDIT_CARD") }
        .to raise_error(ArgumentError, /Invalid payment method/)
    end

    it "raises ArgumentError for an empty string" do
      expect { described_class.validate!("") }
        .to raise_error(ArgumentError)
    end
  end
end
