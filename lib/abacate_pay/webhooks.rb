# frozen_string_literal: true

require "openssl"
require "json"

module AbacatePay
  # Verification and parsing of inbound AbacatePay webhooks.
  #
  # Webhook bodies are the least trusted input an integration handles: they
  # arrive unauthenticated on a public endpoint. Every entry point here treats
  # missing, malformed, and hostile input as an expected case and surfaces it
  # as a typed SDK error, never as a raw parser or NoMethodError.
  module Webhooks
    # Raised when a webhook signature is missing, malformed, or does not match.
    class SignatureError < AbacatePay::Error; end

    # Raised when a webhook body is not a JSON object the SDK can interpret.
    class PayloadError < AbacatePay::Error; end

    # Verifies the `X-Webhook-Signature` header: HMAC-SHA256 over the raw body,
    # base64-encoded, as specified at
    # https://docs.abacatepay.com/pages/webhooks/security
    #
    # Uses Array#pack rather than the base64 gem, which stopped being a default
    # gem in Ruby 3.4.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Your webhook secret/public key
    # @return [true] if signature is valid
    # @raise [SignatureError] if the signature is missing or invalid
    def self.verify!(payload:, signature:, secret:)
      raise SignatureError, "Missing webhook signature" if signature.nil? || signature.to_s.empty?
      raise SignatureError, "Missing webhook secret" if secret.nil? || secret.to_s.empty?

      expected = [OpenSSL::HMAC.digest("SHA256", secret.to_s, payload.to_s)].pack("m0")
      raise SignatureError, "Invalid webhook signature" unless secure_compare(expected, signature.to_s)

      true
    end

    # Checks if a webhook signature is valid.
    #
    # Never raises for untrusted input — a missing header, an empty secret, or a
    # forged signature all return false.
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
    # Prefer {construct_event}, which refuses to parse a body it has not
    # authenticated first.
    #
    # @param payload [String] The raw JSON request body
    # @return [Event] The parsed event
    # @raise [PayloadError] if the body is not a JSON object
    def self.parse(payload)
      data = JSON.parse(payload.to_s)
      raise PayloadError, "Expected a JSON object, got #{data.class}" unless data.is_a?(Hash)

      Event.new(data)
    rescue JSON::ParserError => e
      raise PayloadError, "Malformed webhook payload: #{e.message}"
    end

    # Verifies a webhook signature and parses the body in one step.
    #
    # This is the only entry point that cannot be used to act on an
    # unauthenticated payload, and is what integrations should call.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Your webhook secret/public key
    # @return [Event] The verified, parsed event
    # @raise [SignatureError] if the signature is missing or invalid
    # @raise [PayloadError] if the body is not a JSON object
    def self.construct_event(payload:, signature:, secret:)
      verify!(payload: payload, signature: signature, secret: secret)
      parse(payload)
    end

    # Constant-time comparison to prevent timing attacks.
    #
    # @param expected [String] The signature computed from the payload
    # @param actual [String] The signature supplied by the caller
    # @return [Boolean]
    def self.secure_compare(expected, actual)
      return false unless expected.bytesize == actual.bytesize

      OpenSSL.fixed_length_secure_compare(expected, actual)
    end
    private_class_method :secure_compare
  end
end

require "abacate_pay/webhooks/event"
