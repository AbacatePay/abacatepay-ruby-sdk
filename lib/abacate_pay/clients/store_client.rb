# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for store-level data in the AbacatePay API.
    #
    # Exposes the account balance and revenue reporting for a date range.
    class StoreClient < Client
      def initialize(client = nil)
        super("", client)
      end

      # @return [Resources::Store]
      def get
        response = request("GET", "store/get")
        Resources::Store.new(response)
      end

      # @return [Hash] Merchant info
      def merchant_info
        request("GET", "public-mrr/merchant-info")
      end

      # @return [Hash] MRR metrics
      def mrr
        request("GET", "public-mrr/mrr")
      end

      # @param start_date [String] Start date (YYYY-MM-DD)
      # @param end_date [String] End date (YYYY-MM-DD)
      # @return [Hash] Revenue data
      def revenue(start_date:, end_date:)
        request("GET", "public-mrr/revenue", params: {
                  startDate: start_date,
                  endDate: end_date
                })
      end
    end
  end
end
