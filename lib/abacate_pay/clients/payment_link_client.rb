# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for reusable payment links in the AbacatePay API.
    #
    # A payment link can be paid by many customers independently — mass sales,
    # raffles, sign-up forms — without creating one checkout per customer.
    # Use CheckoutClient when each customer needs their own charge.
    class PaymentLinkClient < Client
      URI = "payment-links"

      # Payment links are always multi-payment by definition; the API rejects
      # any other frequency on this endpoint.
      FREQUENCY = "MULTIPLE_PAYMENTS"

      # @param client [Faraday::Connection, nil] Optional Faraday client
      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Checkouts>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::Checkouts.new(data) }
      end

      # @param id [String] The payment link ID
      # @return [Resources::Checkouts]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::Checkouts.new(response)
      end

      # Creates a reusable payment link.
      #
      # @param data [Resources::Checkouts] The link definition
      # @return [Resources::Checkouts] The created link, with `url` populated
      def create(data)
        response = request("POST", "create", json: build_create_payload(data))
        Resources::Checkouts.new(response)
      end

      # Refunds a payment made through the link.
      #
      # @param id [String] Public charge ID
      # @return [Resources::Checkouts] The refunded charge
      def refund(id)
        response = request("POST", "refund", json: { id: id })
        Resources::Checkouts.new(response)
      end

      private

      # @param data [Resources::Checkouts] The link to serialize
      # @return [Hash] The request payload, with nil entries removed
      def build_create_payload(data)
        {
          frequency: FREQUENCY,
          methods: data.methods,
          items: data.products&.map { |product| { id: product.external_id, quantity: product.quantity } },
          externalId: data.external_id,
          returnUrl: data.metadata&.return_url,
          completionUrl: data.metadata&.completion_url,
          coupons: data.coupons
        }.compact
      end
    end
  end
end
