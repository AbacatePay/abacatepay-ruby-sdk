# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for one-off checkout sessions in the AbacatePay API.
    #
    # Checkouts are single-payment links; use SubscriptionClient for
    # recurring charges.
    class CheckoutClient < Client
      URI = "checkouts"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional filtering params (id, externalId, status, email, taxId, after, before, limit)
      # @return [Array<Resources::Checkouts>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::Checkouts)
      end

      # @param id [String] Checkout ID
      # @return [Resources::Checkouts]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::Checkouts.new(response)
      end

      # @param data [Resources::Checkouts]
      # @return [Resources::Checkouts]
      def create(data)
        response = request("POST", "create", json: build_create_payload(data))
        Resources::Checkouts.new(response)
      end

      # Refunds a paid checkout in full. AbacatePay does not support partial
      # refunds — the original amount is always returned.
      #
      # @param id [String] Public checkout ID (`bill_...`) or charge ID
      #   (`char_...`, `pix_char_...`, `card_...`)
      # @return [Resources::Checkouts] The refunded checkout
      def refund(id)
        response = request("POST", "refund", json: { id: id })
        Resources::Checkouts.new(response)
      end

      private

      # Builds the create-checkout request payload
      #
      # @param data [Resources::Checkouts] The checkout to serialize
      # @return [Hash] The request payload, with nil entries removed
      def build_create_payload(data)
        customer_id = data.customer&.id

        {
          frequency: data.frequency,
          methods: data.methods,
          returnUrl: data.metadata&.return_url,
          completionUrl: data.metadata&.completion_url,
          items: data.products&.map { |product| { id: product.external_id, quantity: product.quantity } },
          externalId: data.external_id,
          coupons: data.coupons,
          customerId: customer_id.to_s.empty? ? nil : customer_id,
          upSellProductId: data.up_sell_product_id,
          metadata: data.custom_metadata
        }.merge(boleto_options(data)).merge(card_options(data)).compact
      end

      # BOLETO-only fields. The API rejects them for other methods, so they are
      # only sent when the caller actually set them.
      #
      # @param data [Resources::Checkouts] The checkout to serialize
      # @return [Hash] The boleto payload fragment
      def boleto_options(data)
        { dueDate: data.due_date, interest: data.interest, fine: data.fine }
      end

      # CARD-only instalment cap, which the API nests under `card`.
      #
      # @param data [Resources::Checkouts] The checkout to serialize
      # @return [Hash] The card payload fragment
      def card_options(data)
        return {} unless data.max_installments

        { card: { maxInstallments: data.max_installments } }
      end
    end
  end
end
