# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::PixTransfers do
  describe "#initialize" do
    context "with API data" do
      let(:transfer) do
        described_class.new({
                              "id" => "pix-1",
                              "amount" => 500,
                              "externalId" => "ext-1",
                              "description" => "Transfer to vendor",
                              "key" => "12345678900",
                              "keyType" => "CPF",
                              "status" => "COMPLETE",
                              "createdAt" => "2026-01-15T10:00:00Z"
                            })
      end

      it("sets id") { expect(transfer.id).to eq("pix-1") }
      it("sets amount") { expect(transfer.amount).to eq(500) }
      it("sets external_id") { expect(transfer.external_id).to eq("ext-1") }
      it("sets key") { expect(transfer.key).to eq("12345678900") }
      it("sets key_type enum") { expect(transfer.key_type).to eq("CPF") }
      it("sets status enum") { expect(transfer.status).to eq("COMPLETE") }
      it("parses created_at") { expect(transfer.created_at).to be_a(DateTime) }
    end

    context "with invalid key_type" do
      it "raises ArgumentError" do
        expect { described_class.new({ "keyType" => "INVALID" }) }
          .to raise_error(ArgumentError)
      end
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        transfer = described_class.new({})
        expect(transfer.id).to be_nil
      end
    end
  end
end
