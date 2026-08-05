# frozen_string_literal: true

module AbacatePay
  module Clients
    # Deprecated client for the v1 billing endpoints.
    #
    # The endpoints this class calls (`/billings/create`, `/billings/list`) do
    # not exist on either API version — v2 replaced them with `/checkouts/*`,
    # and v1 uses the singular `/billing/*`. Every call raises ApiError.
    #
    # Kept only so existing code keeps loading; it will be removed in 2.0.0.
    #
    # @deprecated Use {CheckoutClient} instead.
    class BillingClient < Client
      # API endpoint for billing-related operations
      URI = "billings"

      # @param client [Faraday::Connection, nil] Optional Faraday client for custom configurations
      # @deprecated Use {CheckoutClient} instead
      def initialize(client = nil)
        warn "[DEPRECATION] BillingClient calls /billings/* endpoints that do not exist on the " \
             "AbacatePay API — every request will fail. Use AbacatePay.checkouts instead. " \
             "This class will be removed in 2.0.0."
        super(URI, client)
      end

      # Retrieves a list of billings
      #
      # @return [Array<Resources::Billing>] Array of Billing objects
      def list
        response = request("GET", "list")
        build_list(response, Resources::Billings)
      end

      # Creates a new billing
      #
      # @param data [Resources::Billing] The billing data to be sent for creation
      # @return [Resources::Billing] The created Billing object
      def create(data)
        response = request("POST", "create", json: build_create_payload(data))
        Resources::Billings.new(response)
      end

      private

      # Builds the create-billing request payload
      #
      # @param data [Resources::Billings] The billing to serialize
      # @return [Hash] The request payload
      def build_create_payload(data)
        {
          frequency: data.frequency,
          methods: data.methods,
          returnUrl: data.metadata&.return_url,
          completionUrl: data.metadata&.completion_url,
          items: data.products&.map { |product| serialize_product(product) }
        }.merge(serialize_customer(data.customer))
      end

      # @param product [Resources::Billings::Product] The product to serialize
      # @return [Hash] The product payload
      def serialize_product(product)
        {
          externalId: product.external_id,
          name: product.name,
          description: product.description,
          quantity: product.quantity,
          price: product.price
        }
      end

      # An existing customer is referenced by id; a new one is sent inline.
      #
      # @param customer [Resources::Customers, nil] The customer to serialize
      # @return [Hash] The customer payload fragment
      def serialize_customer(customer)
        return { customerId: customer.id } if customer&.id

        {
          customer: {
            name: customer&.metadata&.name,
            email: customer&.metadata&.email,
            cellphone: customer&.metadata&.cellphone,
            taxId: customer&.metadata&.tax_id
          }
        }
      end
    end
  end
end
