# frozen_string_literal: true

module AbacatePay
  module Clients
    class PixClient < Client
      URI = "pix"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::PixTransfers>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::PixTransfers.new(data) }
      end

      # @param id [String] PIX transfer ID
      # @return [Resources::PixTransfers]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::PixTransfers.new(response)
      end

      # Sends a PIX transfer to an external key.
      # Named send_pix to avoid conflict with Ruby's Object#send.
      #
      # @param data [Resources::PixTransfers]
      # @return [Resources::PixTransfers]
      def send_pix(data)
        response = request("POST", "send", json: {
          amount: data.amount,
          externalId: data.external_id,
          description: data.description,
          key: data.key,
          keyType: data.key_type
        })
        Resources::PixTransfers.new(response)
      end
    end
  end
end
