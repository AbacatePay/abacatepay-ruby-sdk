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
        response.map { |data| Resources::Checkouts.new(data) }
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
          externalId: data.external_id,
          coupons: data.coupons,
          products: data.products&.map { |product|
            {
              externalId: product.external_id,
              name: product.name,
              description: product.description,
              quantity: product.quantity,
              price: product.price
            }
          }
        }

        if data.customer&.id
          request_data[:customerId] = data.customer.id
        elsif data.customer
          request_data[:customer] = {
            name: data.customer.metadata&.name,
            email: data.customer.metadata&.email,
            cellphone: data.customer.metadata&.cellphone,
            taxId: data.customer.metadata&.tax_id
          }
        end

        response = request("POST", "create", json: request_data)
        Resources::Checkouts.new(response)
      end
    end
  end
end
