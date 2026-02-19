# frozen_string_literal: true

require "abacate_pay/resources/customers/metadata"

module AbacatePay
  module Resources
    # Represents a customer resource in the AbacatePay payment system.
    #
    # This class handles customer data including identification and metadata,
    # providing a structured way to manage customer information within the system.
    class Customers < Resource
      # Maps property names to their corresponding resource classes
      RESOURCE_PROPERTIES = {
        metadata: 'AbacatePay::Resources::Customers::Metadata'
      }.freeze

      # @return [String, nil] The unique identifier for the customer
      attr_reader :id

      # @return [Metadata, nil] Additional customer information
      attr_reader :metadata

      # Creates a new Customer instance
      #
      # @param data [Hash] The raw customer data
      # @raise [ArgumentError] If the data is invalid
      def initialize(data)
        fill(data)
      end

      private

      # Process a value based on its property
      #
      # @param property [String] The property name
      # @param value [Object] The value to process
      # @return [Object] The processed value
      def process_value(property, value)
        return nil if value.nil?

        if RESOURCE_PROPERTIES.key?(property.to_sym)
          initialize_resource(
            Object.const_get(RESOURCE_PROPERTIES[property.to_sym]),
            value
          )
        else
          value
        end
      end

      protected

      # @!visibility private
      attr_writer :id, :metadata
    end
  end
end