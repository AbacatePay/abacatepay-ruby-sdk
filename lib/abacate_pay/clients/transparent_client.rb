# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for transparent PIX checkout in the AbacatePay API.
    #
    # Transparent checkout returns the QR code and copy-and-paste
    # payload directly, so the payment stays inside your own UI.
    class TransparentClient < Client
      URI = "transparents"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Transparents>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::Transparents)
      end

      # Creates a transparent charge.
      #
      # @param data [Resources::Transparents] The charge to create
      # @param method [String] "PIX" or "BOLETO"
      # @return [Resources::Transparents]
      # @raise [ArgumentError] if the method is not supported, or if a BOLETO
      #   charge is missing the payer name/taxId the API requires
      def create(data, method: Enums::Billings::Methods::PIX)
        validate_transparent_method!(method)
        validate_boleto_payer!(data) if method == Enums::Billings::Methods::BOLETO

        response = request("POST", "create", json: build_create_payload(data, method))
        Resources::Transparents.new(response)
      end

      # @param id [String] QR code ID
      # @return [Resources::Transparents]
      def check(id)
        response = request("GET", "check", params: { id: id })
        Resources::Transparents.new(response)
      end

      # @param id [String] QR code ID (dev mode only)
      # @return [Resources::Transparents]
      def simulate_payment(id)
        response = request("POST", "simulate-payment", json: { id: id })
        Resources::Transparents.new(response)
      end

      # Refunds a transparent payment in full. AbacatePay does not support
      # partial refunds — the original amount is always returned.
      #
      # @param id [String] Public charge ID (`pix_char_...`, `card_...`, `char_...`)
      # @return [Resources::Transparents] The refunded charge
      def refund(id)
        response = request("POST", "refund", json: { id: id })
        Resources::Transparents.new(response)
      end

      private

      # Only PIX and BOLETO are transparent-checkout methods; CARD goes through
      # the hosted checkout.
      #
      # @param method [String] The requested method
      # @return [void]
      def validate_transparent_method!(method)
        supported = [Enums::Billings::Methods::PIX, Enums::Billings::Methods::BOLETO]
        return if supported.include?(method)

        raise ArgumentError, "Transparent checkout supports #{supported.join(" and ")}, got #{method.inspect}"
      end

      # The API requires the payer's name and taxId for boleto. Failing here
      # names the missing field instead of returning a generic 422.
      #
      # @param data [Resources::Transparents] The charge to validate
      # @return [void]
      def validate_boleto_payer!(data)
        metadata = data.customer&.metadata
        missing = []
        missing << "customer.metadata.name" if metadata&.name.to_s.strip.empty?
        missing << "customer.metadata.tax_id" if metadata&.tax_id.to_s.strip.empty?
        return if missing.empty?

        raise ArgumentError, "BOLETO requires #{missing.join(" and ")}"
      end

      # @param data [Resources::Transparents] The charge to serialize
      # @param method [String] "PIX" or "BOLETO"
      # @return [Hash] The request payload
      def build_create_payload(data, method)
        payload = {
          method: method,
          data: {
            amount: data.amount,
            dueDate: data.due_date
          }.compact,
          expiresIn: data.expires_in,
          description: data.description
        }.compact

        customer = serialize_customer(data.customer)
        payload[:data][:customer] = customer if customer

        payload
      end

      # @param customer [Resources::Customers, nil] The payer
      # @return [Hash, nil] The customer payload, or nil when absent
      def serialize_customer(customer)
        return nil unless customer

        {
          name: customer.metadata&.name,
          email: customer.metadata&.email,
          cellphone: customer.metadata&.cellphone,
          taxId: customer.metadata&.tax_id
        }.compact
      end
    end
  end
end
