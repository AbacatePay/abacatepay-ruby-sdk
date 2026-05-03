# frozen_string_literal: true

require "openssl"
require "base64"
require "json"

module AbacatePay
  module Webhooks
    class SignatureError < AbacatePay::Error; end

    # Fixed AbacatePay HMAC public key, used to sign all webhook deliveries.
    # Per https://docs.abacatepay.com/pages/webhooks/security this is a
    # global, non-secret value — it protects body integrity but does NOT
    # authenticate origin (use the `webhookSecret` query parameter for that).
    PUBLIC_KEY = "t9dXRhHHo3yDEj5pVDYz0frf7q6bMKyMRmxxCPIPp3RCplBfXRxqlC6ZpiWmOqj4L63qEaeUOtrCI8P0VMUgo6iIga2ri9ogaHFs0WIIywSMg0q7RmBfybe1E5XJcfC4IW3alNqym0tXoAKkzvfEjZxV6bE0oG2zJrNNYmUCKZyV0KZ3JS8Votf9EAWWYdiDkMkpbMdPggfh1EqHlVkMiTady6jOR3hyzGEHrIz2Ret0xHKMbiqkr9HS1JhNHDX9"

    # Verifies a webhook signature using HMAC-SHA256 (base64-encoded).
    #
    # The signature is computed over the raw body using AbacatePay's fixed
    # public key (PUBLIC_KEY constant). Callers can override the key for
    # tests or future schemes.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Key used for HMAC. Defaults to PUBLIC_KEY.
    # @return [true] if signature is valid
    # @raise [SignatureError] if signature is invalid
    def self.verify!(payload:, signature:, secret: PUBLIC_KEY)
      expected = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload))
      unless secure_compare(expected, signature.to_s)
        raise SignatureError, "Invalid webhook signature"
      end
      true
    end

    # Checks if a webhook signature is valid.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Key used for HMAC. Defaults to PUBLIC_KEY.
    # @return [Boolean]
    def self.valid?(payload:, signature:, secret: PUBLIC_KEY)
      verify!(payload: payload, signature: signature, secret: secret)
      true
    rescue SignatureError
      false
    end

    # Parses a webhook payload into an Event object.
    #
    # @param payload [String] The raw JSON request body
    # @return [Event] The parsed event
    def self.parse(payload)
      data = JSON.parse(payload)
      Event.new(data)
    end

    # Constant-time string comparison to prevent timing attacks
    def self.secure_compare(a, b)
      return false unless a.bytesize == b.bytesize
      OpenSSL.fixed_length_secure_compare(a, b)
    end
    private_class_method :secure_compare
  end
end

require "abacate_pay/webhooks/event"
