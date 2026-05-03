# frozen_string_literal: true

module AbacatePay
  module Clients
    class ProductClient < Client
      URI = "products"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Products>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::Products.new(data) }
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

        response = request("POST", "create", json: request_data.compact)
        Resources::Products.new(response)
      end

      # @param id [String] Product ID
      # @return [Resources::Products]
      def delete(id)
        response = request("POST", "delete", json: { id: id })
        Resources::Products.new(response)
      end
    end
  end
end
