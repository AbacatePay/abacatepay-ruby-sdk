# frozen_string_literal: true

module AbacatePay
  module Clients
    class CheckoutClient < Client
      URI = "checkouts"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional filtering params (id, externalId, status, email, taxId, after, before, limit)
      # @return [Array<Resources::Checkouts>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::Checkouts.new(data) }
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
        request_data = {
          frequency: data.frequency,
          methods: data.methods,
          returnUrl: data.metadata&.return_url,
          completionUrl: data.metadata&.completion_url,
          items: data.products&.map { |product|
            {
              id: product.external_id,
              quantity: product.quantity
            }
          }
        }

        request_data[:externalId] = data.external_id if data.external_id
        request_data[:coupons] = data.coupons if data.coupons

        customer_id = data.customer&.id
        if customer_id && !customer_id.to_s.empty?
          request_data[:customerId] = customer_id
        end

        response = request("POST", "create", json: request_data.compact)
        Resources::Checkouts.new(response)
      end
    end
  end
end
