# frozen_string_literal: true

require "openssl"
require "base64"

RSpec.describe AbacatePay::Webhooks do
  let(:secret) { "test_webhook_secret_123" }
  let(:payload) { '{"event":"checkout.completed","data":{"id":"chk-1"}}' }
  let(:valid_signature) { Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload)) }

  describe ".verify!" do
    it "returns true for a valid signature" do
      expect(
        described_class.verify!(payload: payload, signature: valid_signature, secret: secret)
      ).to be true
    end

    it "raises SignatureError for an invalid signature" do
      expect {
        described_class.verify!(payload: payload, signature: "invalid", secret: secret)
      }.to raise_error(AbacatePay::Webhooks::SignatureError, /Invalid webhook signature/)
    end

    it "raises SignatureError for a tampered payload" do
      tampered = payload.sub("chk-1", "chk-999")
      expect {
        described_class.verify!(payload: tampered, signature: valid_signature, secret: secret)
      }.to raise_error(AbacatePay::Webhooks::SignatureError)
    end
  end

  describe ".valid?" do
    it "returns true for a valid signature" do
      expect(
        described_class.valid?(payload: payload, signature: valid_signature, secret: secret)
      ).to be true
    end

    it "returns false for an invalid signature" do
      expect(
        described_class.valid?(payload: payload, signature: "bad", secret: secret)
      ).to be false
    end
  end

  describe "default key (PUBLIC_KEY)" do
    it "verifies a signature computed with PUBLIC_KEY when secret kwarg is omitted" do
      sig = Base64.strict_encode64(
        OpenSSL::HMAC.digest("SHA256", AbacatePay::Webhooks::PUBLIC_KEY, payload)
      )
      expect(described_class.verify!(payload: payload, signature: sig)).to be true
    end
  end

  describe ".parse" do
    it "returns an Event object" do
      event = described_class.parse(payload)
      expect(event).to be_a(AbacatePay::Webhooks::Event)
    end

    it "extracts the event type" do
      event = described_class.parse(payload)
      expect(event.type).to eq("checkout.completed")
    end

    it "extracts the data" do
      event = described_class.parse(payload)
      expect(event.data).to eq({ "id" => "chk-1" })
    end
  end
end
