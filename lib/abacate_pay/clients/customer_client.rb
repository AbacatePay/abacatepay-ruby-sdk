# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client class for managing customer-related operations in the AbacatePay API.
    class CustomerClient < Client
      # API endpoint for customer-related operations
      URI = "customers"

      # @param client [Faraday::Connection, nil] Optional Faraday client for custom configurations
      def initialize(client = nil)
        super(URI, client)
      end

      # Retrieves a list of customers
      #
      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Customers>] Array of Customer objects
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        Array(response).map { |data| Resources::Customers.new(data) }
      end

      # Retrieves a customer by ID
      #
      # @param id [String] The customer ID
      # @return [Resources::Customers] The Customer object
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::Customers.new(response)
      end

      # Creates a new customer
      #
      # @param data [Resources::Customers] The customer data to be sent for creation
      # @return [Resources::Customers] The created Customer object
      def create(data)
        response = request("POST", "create", json: {
          name: data.metadata&.name,
          email: data.metadata&.email,
          cellphone: data.metadata&.cellphone,
          taxId: data.metadata&.tax_id
        }.compact)

        Resources::Customers.new(response)
      end

      # Deletes a customer
      #
      # @param id [String] The customer ID
      # @return [Resources::Customers] The deleted Customer object
      def delete(id)
        response = request("POST", "delete", json: { id: id })
        Resources::Customers.new(response)
      end
    end
  end
end