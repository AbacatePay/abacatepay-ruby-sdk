# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Transparents do
  describe "#initialize" do
    context "with API data" do
      let(:transparent) do
        described_class.new({
                              "id" => "tr-1",
                              "amount" => 1000,
                              "status" => "PENDING",
                              "method" => "PIX",
                              "description" => "Test payment",
                              "expiresIn" => 3600,
                              "qrCode" => "00020126...",
                              "qrCodeImage" => "https://example.com/qr.png",
                              "devMode" => true,
                              "createdAt" => "2026-01-15T10:00:00Z",
                              "customer" => { "id" => "cust-1" }
                            })
      end

      it("sets id") { expect(transparent.id).to eq("tr-1") }
      it("sets amount") { expect(transparent.amount).to eq(1000) }
      it("sets status") { expect(transparent.status).to eq("PENDING") }
      it("sets qr_code") { expect(transparent.qr_code).to eq("00020126...") }
      it("sets qr_code_image") { expect(transparent.qr_code_image).to eq("https://example.com/qr.png") }
      it("sets dev_mode?") { expect(transparent.dev_mode?).to be true }
      it("sets customer") { expect(transparent.customer).to be_a(AbacatePay::Resources::Customers) }
      it("parses created_at") { expect(transparent.created_at).to be_a(DateTime) }
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        tr = described_class.new({})
        expect(tr.id).to be_nil
      end
    end
  end
end
