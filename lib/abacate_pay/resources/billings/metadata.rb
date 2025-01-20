# frozen_string_literal: true

module AbacatePay
  module Resources
    module Billings
      # Represents metadata for a billing resource in the AbacatePay system.
      #
      # This class contains additional information related to a billing resource,
      # such as fee, return URL, and completion URL.
      class Metadata < Resource
        # @return [Integer, nil] Fee associated with the billing
        attr_accessor :fee

        # @return [String, nil] URL to redirect the user after payment is canceled or abandoned
        attr_accessor :return_url

        # @return [String, nil] URL to redirect the user after successful payment
        attr_accessor :completion_url

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