# frozen_string_literal: true

module AbacatePay
  module Clients
    class SubscriptionClient < Client
      URI = "subscriptions"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Subscriptions>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        response.map { |data| Resources::Subscriptions.new(data) }
      end

      # @param data [Resources::Subscriptions]
      # @return [Resources::Subscriptions]
      def create(data)
        request_data = {
          methods: data.methods,
          externalId: data.external_id,
          customerId: data.customer&.id,
          items: data.products&.map { |product|
            {
              externalId: product.external_id,
              name: product.name,
              description: product.description,
              quantity: product.quantity,
              price: product.price
            }
          }
        }

        response = request("POST", "create", json: request_data)
        Resources::Subscriptions.new(response)
      end
    end
  end
end
