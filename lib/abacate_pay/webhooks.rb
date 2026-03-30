# frozen_string_literal: true

require "openssl"
require "json"

module AbacatePay
  module Webhooks
    class SignatureError < AbacatePay::Error; end

    # Verifies a webhook signature using HMAC-SHA256.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Your webhook secret/public key
    # @return [true] if signature is valid
    # @raise [SignatureError] if signature is invalid
    def self.verify!(payload:, signature:, secret:)
      expected = OpenSSL::HMAC.hexdigest("SHA256", secret, payload)
      unless secure_compare(expected, signature)
        raise SignatureError, "Invalid webhook signature"
      end
      true
    end

    # Checks if a webhook signature is valid.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Your webhook secret/public key
    # @return [Boolean]
    def self.valid?(payload:, signature:, secret:)
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
