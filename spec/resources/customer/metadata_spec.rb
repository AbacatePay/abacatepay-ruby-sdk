# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Customers::Metadata do
  describe "#initialize" do
    context "with an empty hash" do
      subject(:metadata) { described_class.new({}) }

      it "sets all attributes to nil" do
        expect(metadata.name).to be_nil
        expect(metadata.cellphone).to be_nil
        expect(metadata.email).to be_nil
        expect(metadata.tax_id).to be_nil
      end
    end

    context "with camelCase API data" do
      subject(:metadata) do
        described_class.new(
          "name" => "Maria Silva",
          "cellphone" => "+5511999990000",
          "email" => "maria@example.com",
          "taxId" => "123.456.789-00"
        )
      end

      it "sets name" do
        expect(metadata.name).to eq("Maria Silva")
      end

      it "sets cellphone" do
        expect(metadata.cellphone).to eq("+5511999990000")
      end

      it "sets email" do
        expect(metadata.email).to eq("maria@example.com")
      end

      it "sets tax_id from taxId" do
        expect(metadata.tax_id).to eq("123.456.789-00")
      end
    end
  end

  describe "attribute accessors" do
    subject(:metadata) { described_class.new({}) }

    it "allows setting and reading name" do
      metadata.name = "João Costa"
      expect(metadata.name).to eq("João Costa")
    end

    it "allows setting and reading email" do
      metadata.email = "joao@example.com"
      expect(metadata.email).to eq("joao@example.com")
    end

    it "allows setting and reading cellphone" do
      metadata.cellphone = "+5521988880000"
      expect(metadata.cellphone).to eq("+5521988880000")
    end

    it "allows setting and reading tax_id" do
      metadata.tax_id = "987.654.321-00"
      expect(metadata.tax_id).to eq("987.654.321-00")
    end
  end
end
