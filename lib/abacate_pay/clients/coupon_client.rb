# frozen_string_literal: true

module AbacatePay
  module Clients
    # Client for discount coupons in the AbacatePay API.
    #
    # Supports creating, listing, deleting and toggling coupons
    # between active and inactive.
    class CouponClient < Client
      URI = "coupons"

      def initialize(client = nil)
        super(URI, client)
      end

      # @param params [Hash] Optional pagination params (after, before, limit)
      # @return [Array<Resources::Coupons>]
      def list(**params)
        response = request("GET", "list", params: params.empty? ? nil : params)
        build_list(response, Resources::Coupons)
      end

      # @param id [String] Coupon ID
      # @return [Resources::Coupons]
      def get(id)
        response = request("GET", "get", params: { id: id })
        Resources::Coupons.new(response)
      end

      # @param data [Resources::Coupons]
      # @return [Resources::Coupons]
      def create(data)
        response = request("POST", "create", json: {
                             code: data.code,
                             discount: data.discount,
                             discountKind: data.discount_kind,
                             maxRedeems: data.max_redeems
                           })
        Resources::Coupons.new(response)
      end

      # @param id [String] Coupon ID
      # @return [Resources::Coupons]
      def delete(id)
        response = request("POST", "delete", json: { id: id })
        Resources::Coupons.new(response)
      end

      # @param id [String] Coupon ID
      # @return [Resources::Coupons]
      def toggle(id)
        response = request("POST", "toggle", json: { id: id })
        Resources::Coupons.new(response)
      end
    end
  end
end
