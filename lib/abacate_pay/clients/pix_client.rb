# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for outbound PIX transfers in the AbacatePay API.
    #
    # Transfers are sent to a PIX key; see Enums::Pix::KeyTypes for the
    # accepted key formats.
    class PixClient < Client
      URI = "pix"

      def initialize(client = nil)
        super(URI, client)
      end

      # The API requires an `id` on this endpoint: a bare call fails with
      # "Expected property 'id' to be string but found: undefined". Despite the
      # name it filters rather than lists.
      #
      # @param params [Hash] Params forwarded to the API; `id` is required
      # @return [Array<Resources::PixTransfers>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::PixTransfers)
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
                             # The API nests the destination under `pix`, with
                             # `key` and `type`. Sending pixKey/pixKeyType at the
                             # top level fails with "Property 'pix' is missing";
                             # nesting the wrong names fails with
                             # "Property 'pix.type' is missing".
                             pix: { key: data.key, type: data.key_type }
                           })
        Resources::PixTransfers.new(response)
      end
    end
  end
end
