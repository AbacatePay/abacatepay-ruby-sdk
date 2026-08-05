# frozen_string_literal: true

# Client must load first — every other client inherits from it.
require "abacate_pay/clients/client"

require "abacate_pay/clients/billing_client"
require "abacate_pay/clients/checkout_client"
require "abacate_pay/clients/coupon_client"
require "abacate_pay/clients/customer_client"
require "abacate_pay/clients/payment_link_client"
require "abacate_pay/clients/payout_client"
require "abacate_pay/clients/pix_client"
require "abacate_pay/clients/product_client"
require "abacate_pay/clients/store_client"
require "abacate_pay/clients/subscription_client"
require "abacate_pay/clients/transparent_client"
require "abacate_pay/clients/webhook_client"

module AbacatePay
  # The Clients module contains all API client implementations
  # for interacting with the AbacatePay API endpoints.
  module Clients
  end
end
