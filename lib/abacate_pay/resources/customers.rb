# frozen_string_literal: true

module AbacatePay
  module Resources
    # Represents a customer in the AbacatePay system.
    #
    # The API returns the customer fields at the top level of the object:
    #
    #   { "id": "cust_...", "name": "Ana", "email": "ana@example.com",
    #     "cellphone": "...", "taxId": "...", "metadata": {} }
    #
    # Earlier versions of this class only mapped `id` and a nested `metadata`,
    # so every other field was silently dropped and `customer.metadata.name`
    # came back nil for real API data.
    #
    # Both shapes work now: the fields are exposed directly, and `metadata`
    # keeps answering for code written against the previous interface.
    class Customers < Resource
      RESOURCE_PROPERTIES = {
        metadata: "AbacatePay::Resources::Customers::Metadata"
      }.freeze

      # Fields the API sends inside the customer object.
      IDENTITY_FIELDS = %i[name email cellphone tax_id].freeze

      attr_reader :id, :country, :zip_code, :dev_mode

      # @return [String, nil] Customer's name
      attr_reader :name

      # @return [String, nil] Customer's email address
      attr_reader :email

      # @return [String, nil] Customer's cellphone number
      attr_reader :cellphone

      # @return [String, nil] Customer's tax identification number
      attr_reader :tax_id

      # @param data [Hash] The customer properties
      def initialize(data)
        fill(data)
      end

      # @return [Boolean, nil] Whether this customer belongs to Dev mode
      def dev_mode?
        @dev_mode
      end

      # The identity fields, wrapped.
      #
      # Kept because `customer.metadata.name` is what the README documented and
      # what existing integrations call. When the API sends the fields at the
      # top level, this builds the wrapper from them rather than returning the
      # empty object the API puts in `metadata`.
      #
      # @return [Customers::Metadata, nil]
      def metadata
        return @metadata if metadata_populated?(@metadata)

        identity = IDENTITY_FIELDS.to_h { |field| [field, public_send(field)] }.compact
        return @metadata if identity.empty?

        Customers::Metadata.new(identity)
      end

      private

      # @param metadata [Customers::Metadata, nil]
      # @return [Boolean] Whether the API actually filled the nested object
      def metadata_populated?(metadata)
        return false if metadata.nil?

        IDENTITY_FIELDS.any? { |field| metadata.public_send(field) }
      end

      # @param property [String] The property name
      # @param value [Object] The raw value
      # @return [Object] The processed value
      def process_value(property, value)
        return nil if value.nil?

        if RESOURCE_PROPERTIES.key?(property.to_sym)
          initialize_resource(Object.const_get(RESOURCE_PROPERTIES[property.to_sym]), value)
        else
          value
        end
      end

      protected

      attr_writer :id, :metadata, :name, :email, :cellphone, :tax_id,
                  :country, :zip_code, :dev_mode
    end
  end
end

require "abacate_pay/resources/customers/metadata"
