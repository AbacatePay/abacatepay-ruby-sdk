# frozen_string_literal: true

# Entry point matching the gem name.
#
# Bundler requires a gem by its own name, so `gem "abacatepay-ruby"` in a
# Gemfile makes Rails call `require "abacatepay-ruby"` (and then
# `require "abacatepay/ruby"`). Neither matched `lib/abacate_pay.rb`, so the SDK
# silently failed to load and the first call raised
# `undefined method 'configure' for module AbacatePay` — the module existed with
# only VERSION in it, defined as a side effect of the gemspec.
#
# This file makes the default `gem "abacatepay-ruby"` work without a `require:`
# option. `require "abacate_pay"` keeps working for anyone already using it.
require_relative "abacate_pay"
