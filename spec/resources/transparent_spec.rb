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

    # Shape real da API (produção/sandbox atuais): o copia-e-cola vem como
    # `brCode` e a imagem como `brCodeBase64` (data URI), com `expiresAt` e
    # `platformFee`.
    context "with brCode-shaped API data" do
      let(:transparent) do
        described_class.new({
          "id" => "pix_char_123",
          "amount" => 100,
          "status" => "PENDING",
          "devMode" => true,
          "brCode" => "00020101021126580014BR.GOV.BCB.PIX...",
          "brCodeBase64" => "data:image/png;base64,iVBOR...",
          "platformFee" => 80,
          "receiptUrl" => nil,
          "expiresAt" => "2026-02-01T10:00:00Z"
        })
      end

      it("exposes br_code") { expect(transparent.br_code).to start_with("00020101") }
      it("exposes br_code_base64") { expect(transparent.br_code_base64).to start_with("data:image/png") }
      it("falls back qr_code to br_code") { expect(transparent.qr_code).to eq(transparent.br_code) }
      it("falls back qr_code_image to br_code_base64") { expect(transparent.qr_code_image).to eq(transparent.br_code_base64) }
      it("sets platform_fee") { expect(transparent.platform_fee).to eq(80) }
      it("parses expires_at") { expect(transparent.expires_at).to be_a(DateTime) }
    end

    context "with legacy qrCode-shaped data" do
      let(:transparent) do
        described_class.new({ "qrCode" => "00020126...", "qrCodeImage" => "https://example.com/qr.png" })
      end

      it("still exposes qr_code") { expect(transparent.qr_code).to eq("00020126...") }
      it("still exposes qr_code_image") { expect(transparent.qr_code_image).to eq("https://example.com/qr.png") }
    end

    context "with empty data" do
      it "sets all attributes to nil" do
        tr = described_class.new({})
        expect(tr.id).to be_nil
        expect(tr.qr_code).to be_nil
      end
    end
  end
end
