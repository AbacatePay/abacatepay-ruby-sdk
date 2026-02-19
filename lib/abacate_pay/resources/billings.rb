# frozen_string_literal: true

require "abacate_pay/resources/billings/metadata"
require "abacate_pay/resources/billings/product"

module AbacatePay
  module Resources
    # Represents a billing resource in the AbacatePay payment system.
    #
    # Manages billing-related data including payment methods, products, scheduling,
    # and customer information for recurring and one-time payments.
    class Billings < Resource
      # Maps property names to their corresponding resource classes
      RESOURCE_PROPERTIES = {
        metadata: 'AbacatePay::Resources::Billings::Metadata',
        customer: 'AbacatePay::Resources::Customers',
        products: 'AbacatePay::Resources::Billings::Product'
      }.freeze

      # Maps property names to their corresponding enum classes
      ENUM_PROPERTIES = {
        status: 'AbacatePay::Enums::Billings::Statuses',
        frequency: 'AbacatePay::Enums::Billings::Frequencies',
        methods: 'AbacatePay::Enums::Billings::Methods'
      }.freeze

      # Properties that should be handled as DateTime objects
      DATETIME_PROPERTIES = %w[
        next_billing
        created_at
        updated_at
      ].freeze

      # Basic attributes
      attr_reader :id, :account_id, :url, :dev_mode, :amount

      # Complex attributes
      attr_reader :methods, :products, :metadata, :customer

      # Enum attributes
      attr_reader :frequency, :status

      # DateTime attributes
      attr_reader :next_billing, :created_at, :updated_at

      # Creates a new Billing instance
      #
      # @param data [Hash] The raw billing data
      # @raise [ArgumentError] If the data is invalid
      def initialize(data)
        fill(data)
      end

      # Checks if billing is in development mode
      #
      # @return [Boolean, nil] True if in dev mode, false if not, or nil if not set
      def dev_mode?
        @dev_mode
      end

      private

      # Process a value based on its property
      #
      # @param property [String] The property name
      # @param value [Object] The value to process
      # @return [Object] The processed value
      def process_value(property, value)
        return nil if value.nil?

        if DATETIME_PROPERTIES.include?(property)
          initialize_date_time(value)
        elsif ENUM_PROPERTIES.key?(property.to_sym)
          process_enum_value(property, value)
        elsif RESOURCE_PROPERTIES.key?(property.to_sym)
          process_resource_value(property, value)
        else
          value
        end
      end

      # Process enum values
      #
      # @param property [String] The property name
      # @param value [Object] The value to process
      # @return [Object] The processed value
      def process_enum_value(property, value)
        enum_class = Object.const_get(ENUM_PROPERTIES[property.to_sym])
        
        if value.is_a?(Array)
          value.map { |item| initialize_enum(enum_class, item) }
        else
          initialize_enum(enum_class, value)
        end
      end

      # Process resource values
      #
      # @param property [String] The property name
      # @param value [Object] The value to process
      # @return [Object] The processed value
      def process_resource_value(property, value)
        resource_class = Object.const_get(RESOURCE_PROPERTIES[property.to_sym])
        
        if property.to_s == 'products' && value.is_a?(Array)
          value.map { |item| initialize_resource(resource_class, item) }
        else
          initialize_resource(resource_class, value)
        end
      end

      protected

      # @!visibility private
      attr_writer :id, :account_id, :url, :methods, :products,
                 :dev_mode, :amount, :metadata, :frequency, :status,
                 :customer, :next_billing, :created_at, :updated_at
    end
  end
end