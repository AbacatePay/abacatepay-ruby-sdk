# frozen_string_literal: true

RSpec.describe AbacatePay::Enums::Pix::KeyTypes do
  describe ".values" do
    it "returns all valid key types" do
      expect(described_class.values).to contain_exactly(
        "CPF", "CNPJ", "PHONE", "EMAIL", "RANDOM", "BR_CODE"
      )
    end
  end

  describe ".valid?" do
    it("returns true for CPF") { expect(described_class.valid?("CPF")).to be true }
    it("returns true for BR_CODE") { expect(described_class.valid?("BR_CODE")).to be true }
    it("returns false for PIX") { expect(described_class.valid?("PIX")).to be false }
  end

  describe ".validate!" do
    it "returns the value when valid" do
      expect(described_class.validate!("EMAIL")).to eq("EMAIL")
    end

    it "raises ArgumentError for an invalid key type" do
      expect { described_class.validate!("INVALID") }.to raise_error(ArgumentError)
    end
  end
end
