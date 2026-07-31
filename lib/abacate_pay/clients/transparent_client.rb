# frozen_string_literal: true

module AbacatePay
  module Clients
    class TransparentClient < Client
      URI = "transparents"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Transparents>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::Transparents.new(data) }
      end

      # @param data [Resources::Transparents]
      # @return [Resources::Transparents]
      def create(data)
        request_data = {
          method: "PIX",
          data: {
            amount: data.amount
          },
          expiresIn: data.expires_in,
          description: data.description
        }

        if data.customer
          request_data[:customer] = {
            name: data.customer.metadata&.name,
            email: data.customer.metadata&.email,
            cellphone: data.customer.metadata&.cellphone,
            taxId: data.customer.metadata&.tax_id
          }
        end

        response = request("POST", "create", json: request_data)
        Resources::Transparents.new(response)
      end

      # @param id [String] QR code ID
      # @return [Resources::Transparents]
      def check(id)
        response = request("GET", "check", params: { id: id })
        Resources::Transparents.new(response)
      end

      # @param id [String] QR code ID (dev mode only)
      # @return [Resources::Transparents]
      def simulate_payment(id)
        # The API expects the id as a query string param (like #check), not in
        # the JSON body — body-only requests fail with "Expected property 'id'".
        response = request("POST", "simulate-payment", params: { id: id }, json: {})
        Resources::Transparents.new(response)
      end
    end
  end
end
