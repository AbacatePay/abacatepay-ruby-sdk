# frozen_string_literal: true

module AbacatePay
  module Resources
    class Store < Resource
      # Represents the available balance of a store.
      class Balance < Resource
        attr_reader :available, :pending, :blocked

        def initialize(data)
          fill(data)
        end

        protected

        attr_writer :available, :pending, :blocked
      end
    end
  end
end
