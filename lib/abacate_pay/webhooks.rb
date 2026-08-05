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

    # AbacatePay signs every delivery with this fixed key, published at
    # https://docs.abacatepay.com/pages/webhooks/security and hard-coded in the
    # Node, Python and Go samples there.
    #
    # It is public and global, so it proves only that the body was not altered
    # in transit, it does NOT prove the request came from AbacatePay, since
    # anyone can compute a valid signature with it. Origin is authenticated by
    # the `webhookSecret` query parameter; see {verify_secret!}. Use both.
    PUBLIC_KEY = "t9dXRhHHo3yDEj5pVDYz0frf7q6bMKyMRmxxCPIPp3RCplBfXRxqlC6ZpiWmOqj4L63qEaeUOtrCI8P0VMU" \
                 "go6iIga2ri9ogaHFs0WIIywSMg0q7RmBfybe1E5XJcfC4IW3alNqym0tXoAKkzvfEjZxV6bE0oG2zJrNNYmU" \
                 "CKZyV0KZ3JS8Votf9EAWWYdiDkMkpbMdPggfh1EqHlVkMiTady6jOR3hyzGEHrIz2Ret0xHKMbiqkr9HS1Jh" \
                 "NHDX9"

    # Verifies the `X-Webhook-Signature` header: HMAC-SHA256 over the raw body,
    # base64-encoded.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] HMAC key. Defaults to {PUBLIC_KEY}, which is what
    #   AbacatePay signs with.
    # @return [true] if signature is valid
    # @raise [SignatureError] if the signature is missing or invalid
    def self.verify!(payload:, signature:, secret: PUBLIC_KEY)
      raise SignatureError, "Missing webhook signature" if signature.nil? || signature.to_s.empty?
      raise SignatureError, "Missing webhook secret" if secret.nil? || secret.to_s.empty?

      expected = base64_hmac(secret.to_s, payload.to_s)
      raise SignatureError, "Invalid webhook signature" unless secure_compare(expected, signature.to_s)

      true
    end

    # Verifies the `webhookSecret` query parameter, which is what actually
    # authenticates the request as coming from AbacatePay.
    #
    # The HMAC signature alone cannot do this: it is computed with a public key.
    #
    # @param received [String] The `webhookSecret` query parameter as received
    # @param expected [String] The secret you configured on the webhook
    # @return [true] if they match
    # @raise [SignatureError] if either is missing or they differ
    def self.verify_secret!(received:, expected:)
      raise SignatureError, "Missing webhook secret parameter" if received.nil? || received.to_s.empty?
      raise SignatureError, "Missing expected webhook secret" if expected.nil? || expected.to_s.empty?
      raise SignatureError, "Invalid webhook secret" unless secure_compare(expected.to_s, received.to_s)

      true
    end

    # Checks if a webhook signature is valid.
    #
    # Never raises for untrusted input, a missing header, an empty secret, or a
    # forged signature all return false.
    #
    # @param payload [String] The raw request body
    # @param signature [String] The X-Webhook-Signature header value
    # @param secret [String] Your webhook secret/public key
    # @return [Boolean]
    def self.valid?(payload:, signature:, secret: PUBLIC_KEY)
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
    def self.construct_event(payload:, signature:, secret: PUBLIC_KEY)
      verify!(payload: payload, signature: signature, secret: secret)
      parse(payload)
    end

    # Base64-encoded HMAC-SHA256, matching what AbacatePay sends.
    #
    # Uses Array#pack rather than the base64 gem: base64 stopped being a default
    # gem in Ruby 3.4, and requiring it would add a runtime dependency for one
    # call.
    #
    # @param secret [String] The HMAC key
    # @param payload [String] The raw body
    # @return [String] The base64 signature
    def self.base64_hmac(secret, payload)
      [OpenSSL::HMAC.digest("SHA256", secret, payload)].pack("m0")
    end
    private_class_method :base64_hmac

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
