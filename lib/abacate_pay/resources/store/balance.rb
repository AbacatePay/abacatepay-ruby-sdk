# frozen_string_literal: true

module AbacatePay
  module Resources
    class Store < Resource
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
