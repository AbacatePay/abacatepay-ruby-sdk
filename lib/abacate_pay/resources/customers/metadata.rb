# frozen_string_literal: true

module AbacatePay
  module Resources
    module Customers
      # Represents metadata for a customer in the AbacatePay system.
      #
      # This class contains additional information about a customer, such as their name,
      # contact details, and tax identification number.
      class Metadata < Resource
        # @return [String, nil] Customer's name
        attr_accessor :name

        # @return [String, nil] Customer's cellphone number
        attr_accessor :cellphone

        # @return [String, nil] Customer's email address
        attr_accessor :email

        # @return [String, nil] Customer's tax identification number
        attr_accessor :tax_id

        # Creates a new Metadata instance
        #
        # @param data [Hash] The metadata properties
        def initialize(data)
          fill(data)
        end

        protected

        def to_hash
          super
        end
      end
    end
  end
end