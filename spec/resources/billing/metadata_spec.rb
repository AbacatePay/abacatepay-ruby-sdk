# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Billings::Metadata do
  describe "#initialize" do
    context "with an empty hash" do
      subject(:metadata) { described_class.new({}) }

      it "sets fee to nil" do
        expect(metadata.fee).to be_nil
      end

      it "sets return_url to nil" do
        expect(metadata.return_url).to be_nil
      end

      it "sets completion_url to nil" do
        expect(metadata.completion_url).to be_nil
      end
    end

    context "with camelCase API data" do
      subject(:metadata) do
        described_class.new(
          "fee" => 250,
          "returnUrl" => "https://example.com/return",
          "completionUrl" => "https://example.com/complete"
        )
      end

      it "sets the fee" do
        expect(metadata.fee).to eq(250)
      end

      it "sets return_url from the returnUrl key" do
        expect(metadata.return_url).to eq("https://example.com/return")
      end

      it "sets completion_url from the completionUrl key" do
        expect(metadata.completion_url).to eq("https://example.com/complete")
      end
    end
  end

  describe "attribute accessors" do
    subject(:metadata) { described_class.new({}) }

    it "allows setting and reading fee" do
      metadata.fee = 500
      expect(metadata.fee).to eq(500)
    end

    it "allows setting and reading return_url" do
      metadata.return_url = "https://pay.example.com/cancel"
      expect(metadata.return_url).to eq("https://pay.example.com/cancel")
    end

    it "allows setting and reading completion_url" do
      metadata.completion_url = "https://pay.example.com/success"
      expect(metadata.completion_url).to eq("https://pay.example.com/success")
    end
  end
end
