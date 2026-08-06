# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for the product catalogue in the AbacatePay API.
    #
    # Products are the line items referenced by billings and checkouts.
    class ProductClient < Client
      URI = "products"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Products>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::Products)
      end

      # @param id [String] Product ID or externalId
      # @return [Resources::Products]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::Products.new(response)
      end

      # @param data [Resources::Products]
      # @return [Resources::Products]
      def create(data)
        request_data = {
          externalId: data.external_id,
          name: data.name,
          price: data.price,
          currency: data.currency || "BRL",
          description: data.description
        }
        request_data[:imageUrl] = data.image_url if data.image_url && !data.image_url.to_s.empty?
        request_data[:cycle] = data.cycle if data.cycle && !data.cycle.to_s.empty?

        response = request("POST", "create", json: request_data)
        Resources::Products.new(response)
      end

      # @param id [String] Product ID
      # @return [Resources::Products]
      def delete(id)
        # The API reads the id from the query string on delete endpoints.
        # Sending it only in the body fails with
        # "Expected property 'id' to be string but found: undefined".
        response = request("POST", "delete", params: { id: id }, json: {})
        Resources::Products.new(response)
      end
    end
  end
end
