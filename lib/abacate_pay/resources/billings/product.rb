# frozen_string_literal: true

module AbacatePay
  module Resources
    module Billings
      # Represents a product in a billing resource in the AbacatePay system.
      #
      # This class contains information about a product, such as its identifier,
      # name, description, quantity, and price.
      class Product < Resource
        # @return [String, nil] External identifier for the product
        attr_accessor :external_id

        # @return [String, nil] Internal identifier for the product in the system
        attr_accessor :product_id

        # @return [String, nil] Name of the product
        attr_accessor :name

        # @return [String, nil] Description of the product
        attr_accessor :description

        # @return [Integer, nil] Quantity of the product
        attr_accessor :quantity

        # @return [Integer, nil] Price of the product in smallest currency unit (e.g., cents)
        attr_accessor :price

        # Creates a new Product instance
        #
        # @param data [Hash] The product properties
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