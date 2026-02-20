# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Billings::Product do
  describe "#initialize" do
    context "with an empty hash" do
      subject(:product) { described_class.new({}) }

      it "sets all attributes to nil" do
        expect(product.external_id).to be_nil
        expect(product.product_id).to be_nil
        expect(product.name).to be_nil
        expect(product.description).to be_nil
        expect(product.quantity).to be_nil
        expect(product.price).to be_nil
      end
    end

    context "with camelCase API data" do
      subject(:product) do
        described_class.new(
          "externalId" => "ext-001",
          "productId" => "prod-abc",
          "name" => "Avocado",
          "description" => "Fresh avocado",
          "quantity" => 3,
          "price" => 1500
        )
      end

      it "sets external_id from externalId" do
        expect(product.external_id).to eq("ext-001")
      end

      it "sets product_id from productId" do
        expect(product.product_id).to eq("prod-abc")
      end

      it "sets name" do
        expect(product.name).to eq("Avocado")
      end

      it "sets description" do
        expect(product.description).to eq("Fresh avocado")
      end

      it "sets quantity" do
        expect(product.quantity).to eq(3)
      end

      it "sets price in smallest currency unit" do
        expect(product.price).to eq(1500)
      end
    end
  end

  describe "attribute accessors" do
    subject(:product) { described_class.new({}) }

    it "allows setting and reading external_id" do
      product.external_id = "ext-999"
      expect(product.external_id).to eq("ext-999")
    end

    it "allows setting and reading name" do
      product.name = "Widget"
      expect(product.name).to eq("Widget")
    end

    it "allows setting and reading price" do
      product.price = 9999
      expect(product.price).to eq(9999)
    end

    it "allows setting and reading quantity" do
      product.quantity = 5
      expect(product.quantity).to eq(5)
    end
  end
end
