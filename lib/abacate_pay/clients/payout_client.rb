# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for payouts (withdrawals) in the AbacatePay API.
    #
    # Payouts move settled balance out of the store account.
    class PayoutClient < Client
      URI = "payouts"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Payouts>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::Payouts)
      end

      # @param id [String] Payout ID
      # @return [Resources::Payouts]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::Payouts.new(response)
      end

      # @param data [Resources::Payouts]
      # @return [Resources::Payouts]
      def create(data)
        response = request("POST", "create", json: {
                             amount: data.amount,
                             externalId: data.external_id,
                             description: data.description,
                             # The API nests the destination under `pix`, with
                             # `key` and `type`. Sending pixKey/pixKeyType at the
                             # top level fails with "Property 'pix' is missing";
                             # nesting the wrong names fails with
                             # "Property 'pix.type' is missing".
                             pix: { key: data.pix_key, type: data.pix_key_type }
                           })
        Resources::Payouts.new(response)
      end
    end
  end
end
