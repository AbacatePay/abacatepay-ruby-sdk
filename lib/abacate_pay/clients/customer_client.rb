# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client class for managing customer-related operations in the AbacatePay API.
    class CustomerClient < Client
      # API endpoint for customer-related operations
      URI = "customer"

      # @param client [Faraday::Connection, nil] Optional Faraday client for custom configurations
      def initialize(client = nil)
        super(URI, client)
      end

      # Retrieves a list of customers
      #
      # @return [Array<Resources::Customer>] Array of Customer objects
      def list
        response = request("GET", "list")
        response.map { |data| Resources::Customers.new(data) }
      end

      # Creates a new customer
      #
      # @param data [Resources::Customer] The customer data to be sent for creation
      # @return [Resources::Customer] The created Customer object
      def create(data)
        response = request("POST", "create", json: {
          name: data.metadata&.name,
          email: data.metadata&.email,
          cellphone: data.metadata&.cellphone,
          taxId: data.metadata&.tax_id
        })

        Resources::Customers.new(response)
      end
    end
  end
end