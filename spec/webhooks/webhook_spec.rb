# frozen_string_literal: true

require "openssl"

RSpec.describe AbacatePay::Webhooks do
  let(:secret) { "test_webhook_secret_123" }
  let(:payload) { '{"event":"checkout.completed","data":{"id":"chk-1"}}' }
  let(:valid_signature) { OpenSSL::HMAC.hexdigest("SHA256", secret, payload) }

  describe ".verify!" do
    it "returns true for a valid signature" do
      expect(
        described_class.verify!(payload: payload, signature: valid_signature, secret: secret)
      ).to be true
    end

    it "raises SignatureError for an invalid signature" do
      expect do
        described_class.verify!(payload: payload, signature: "invalid", secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError, /Invalid webhook signature/)
    end

    it "raises SignatureError for a tampered payload" do
      tampered = payload.sub("chk-1", "chk-999")
      expect do
        described_class.verify!(payload: tampered, signature: valid_signature, secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError)
    end

    # A request with no X-Webhook-Signature header reaches the SDK as nil.
    it "raises SignatureError when the signature header is absent" do
      expect do
        described_class.verify!(payload: payload, signature: nil, secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError, /Missing webhook signature/)
    end

    it "raises SignatureError when the signature header is empty" do
      expect do
        described_class.verify!(payload: payload, signature: "", secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError, /Missing webhook signature/)
    end

    it "raises SignatureError when the secret is not configured" do
      expect do
        described_class.verify!(payload: payload, signature: valid_signature, secret: nil)
      end.to raise_error(AbacatePay::Webhooks::SignatureError, /Missing webhook secret/)
    end

    it "raises SignatureError for a signature of a different length" do
      expect do
        described_class.verify!(payload: payload, signature: "#{valid_signature}extra", secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError, /Invalid webhook signature/)
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

    # Documented as returning a Boolean — it must never raise for hostile input.
    it "returns false when the signature header is absent" do
      expect(
        described_class.valid?(payload: payload, signature: nil, secret: secret)
      ).to be false
    end

    it "returns false when the secret is not configured" do
      expect(
        described_class.valid?(payload: payload, signature: valid_signature, secret: nil)
      ).to be false
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

    it "raises PayloadError for malformed JSON" do
      expect do
        described_class.parse("not json at all")
      end.to raise_error(AbacatePay::Webhooks::PayloadError, /Malformed webhook payload/)
    end

    it "raises PayloadError for JSON that is not an object" do
      expect do
        described_class.parse("[1,2,3]")
      end.to raise_error(AbacatePay::Webhooks::PayloadError, /Expected a JSON object/)
    end

    it "raises PayloadError for an empty body" do
      expect do
        described_class.parse("")
      end.to raise_error(AbacatePay::Webhooks::PayloadError)
    end
  end

  describe ".construct_event" do
    it "returns the parsed Event when the signature is valid" do
      event = described_class.construct_event(payload: payload, signature: valid_signature, secret: secret)

      expect(event.type).to eq("checkout.completed")
    end

    it "refuses to parse a payload with an invalid signature" do
      expect do
        described_class.construct_event(payload: payload, signature: "forged", secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError)
    end

    # The signature must be checked before the body is even parsed.
    it "reports the signature failure, not the payload failure, for an unsigned malformed body" do
      expect do
        described_class.construct_event(payload: "not json", signature: nil, secret: secret)
      end.to raise_error(AbacatePay::Webhooks::SignatureError)
    end
  end
end
