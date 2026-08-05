# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for recurring subscriptions in the AbacatePay API.
    #
    # See Enums::Products::Cycles for the supported billing cycles.
    class SubscriptionClient < Client
      URI = "subscriptions"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Subscriptions>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::Subscriptions.new(data) }
      end

      # @param data [Resources::Subscriptions]
      # @return [Resources::Subscriptions]
      def create(data)
        request_data = {
          methods: data.methods,
          externalId: data.external_id,
          customerId: data.customer&.id,
          items: data.products&.map do |product|
            {
              externalId: product.external_id,
              name: product.name,
              description: product.description,
              quantity: product.quantity,
              price: product.price
            }
          end
        }

        response = request("POST", "create", json: request_data)
        Resources::Subscriptions.new(response)
      end

      # Cancels an active subscription immediately. Pending future instalments
      # are cancelled along with it.
      #
      # @param id [String] The subscription ID (`subs_...`)
      # @return [Resources::Subscriptions] The cancelled subscription
      def cancel(id)
        response = request("POST", "cancel", json: { id: id })
        Resources::Subscriptions.new(response)
      end
    end
  end
end
