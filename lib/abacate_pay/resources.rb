# frozen_string_literal: true

# Resource must load first: every other resource inherits from it.
require "abacate_pay/resources/resource"

require "abacate_pay/resources/billings"
require "abacate_pay/resources/billings/metadata"
require "abacate_pay/resources/billings/product"
require "abacate_pay/resources/checkouts"
require "abacate_pay/resources/coupons"
require "abacate_pay/resources/customers"
require "abacate_pay/resources/customers/metadata"
require "abacate_pay/resources/payouts"
require "abacate_pay/resources/pix_transfers"
require "abacate_pay/resources/products"
require "abacate_pay/resources/store"
require "abacate_pay/resources/store/balance"
require "abacate_pay/resources/subscriptions"
require "abacate_pay/resources/transparents"
require "abacate_pay/resources/webhook_endpoints"

module AbacatePay
  # The Resources module contains all resource classes that
  # represent the various entities in the AbacatePay system.
  module Resources
  end
end
