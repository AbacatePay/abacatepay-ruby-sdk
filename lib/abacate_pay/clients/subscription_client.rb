# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for recurring subscriptions in the AbacatePay API.
    #
    # See Enums::Products::Cycles for the supported billing cycles.
    class SubscriptionClient < Client
      URI = "subscriptions"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Subscriptions>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::Subscriptions)
      end

      # @param data [Resources::Subscriptions]
      # @return [Resources::Subscriptions]
      def create(data)
        request_data = {
          methods: data.methods,
          externalId: data.external_id,
          customerId: data.customer&.id,
          # The API expects the product id here, the same shape checkouts use.
          # Sending externalId fails with
          # "Expected property 'items.0.id' to be string".
          items: data.products&.map { |product| { id: product.external_id, quantity: product.quantity } }
        }

        response = request("POST", "create", json: request_data)
        Resources::Subscriptions.new(response)
      end

      # Cancels an active subscription immediately. Pending future instalments
      # are cancelled along with it.
      #
      # @param id [String] The subscription ID (`subs_...`)
      # @return [Resources::Subscriptions] The cancelled subscription
      def cancel(id)
        response = request("POST", "cancel", json: { id: id })
        Resources::Subscriptions.new(response)
      end

      # Changes the main product of an active subscription. The new price takes
      # effect on the next billing cycle, the current cycle is untouched.
      #
      # @param id [String] The subscription ID (`subs_...`)
      # @param product_id [String] The new product ID (`prod_...`), which must have a cycle
      # @param quantity [Integer] Quantity of the product, minimum 1
      # @return [Hash] The pending update object (`status: "PENDING"`)
      # @raise [ArgumentError] if quantity is below 1
      def change_plan(id, product_id:, quantity: 1)
        raise ArgumentError, "quantity must be at least 1, got #{quantity.inspect}" if quantity.to_i < 1

        request("POST", "change-plan", json: { id: id, productId: product_id, quantity: quantity.to_i })
      end

      # Records usage of a pay-as-you-go product on an active subscription. The
      # amount is added to the next pending instalment of the cycle.
      #
      # @param id [String] The subscription ID (`subs_...`)
      # @param product_id [String] The usage product ID (`prod_...`), which must NOT have a cycle
      # @param units [Integer] Number of units, minimum 1
      # @param action [String] "add" to add units, "subtract" to reverse units
      #   already recorded in the same cycle
      # @return [Hash] The recorded usage
      # @raise [ArgumentError] if units is below 1 or action is not add/subtract
      def record_usage(id, product_id:, units:, action: "add")
        raise ArgumentError, "units must be at least 1, got #{units.inspect}" if units.to_i < 1

        unless %w[add subtract].include?(action.to_s)
          raise ArgumentError, "action must be \"add\" or \"subtract\", got #{action.inspect}"
        end

        request("POST", "record-usage",
                json: { id: id, productId: product_id, units: units.to_i, action: action.to_s })
      end
    end
  end
end
