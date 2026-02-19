# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client class for managing billing-related operations in the AbacatePay API.
    class BillingClient < Client
      # API endpoint for billing-related operations
      URI = "billing"

      # @param client [Faraday::Connection, nil] Optional Faraday client for custom configurations
      def initialize(client = nil)
        super(URI, client)
      end

      # Retrieves a list of billings
      #
      # @return [Array<Resources::Billing>] Array of Billing objects
      def list
        response = request("GET", "list")
        response.map { |data| Resources::Billings.new(data) }
      end

      # Creates a new billing
      #
      # @param data [Resources::Billing] The billing data to be sent for creation
      # @return [Resources::Billing] The created Billing object
      def create(data)
        request_data = {
          frequency: data.frequency,
          methods: data.methods,
          returnUrl: data.metadata&.return_url,
          completionUrl: data.metadata&.completion_url,
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
        else
          request_data[:customer] = {
            name: data.customer&.metadata&.name,
            email: data.customer&.metadata&.email,
            cellphone: data.customer&.metadata&.cellphone,
            taxId: data.customer&.metadata&.tax_id
          }
        end

        response = request("POST", "create", json: request_data)
        Resources::Billings.new(response)
      end
    end
  end
end