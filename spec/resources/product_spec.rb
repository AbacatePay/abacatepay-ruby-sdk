# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Products do
  describe "#initialize" do
    context "with API data" do
      let(:product) do
        described_class.new({
          "id" => "prod-1",
          "externalId" => "ext-1",
          "name" => "Test Product",
          "price" => 1500,
          "currency" => "BRL",
          "description" => "A test product",
          "imageUrl" => "https://example.com/img.png",
          "cycle" => "MONTHLY",
          "createdAt" => "2026-01-15T10:00:00Z",
          "updatedAt" => "2026-01-15T12:00:00Z"
        })
      end

      it("sets id") { expect(product.id).to eq("prod-1") }
      it("sets external_id") { expect(product.external_id).to eq("ext-1") }
      it("sets name") { expect(product.name).to eq("Test Product") }
      it("sets price") { expect(product.price).to eq(1500) }
      it("sets currency") { expect(product.currency).to eq("BRL") }
      it("sets description") { expect(product.description).to eq("A test product") }
      it("sets image_url") { expect(product.image_url).to eq("https://example.com/img.png") }
      it("sets cycle enum") { expect(product.cycle).to eq("MONTHLY") }
      it("parses created_at") { expect(product.created_at).to be_a(DateTime) }
      it("parses updated_at") { expect(product.updated_at).to be_a(DateTime) }
    end

    context "with empty data" do
      let(:product) { described_class.new({}) }

      it("sets all attributes to nil") do
        expect(product.id).to be_nil
        expect(product.name).to be_nil
        expect(product.price).to be_nil
      end
    end

    context "with invalid cycle" do
      it "raises ArgumentError" do
        expect { described_class.new({ "cycle" => "DAILY" }) }
          .to raise_error(ArgumentError)
      end
    end
  end
end
