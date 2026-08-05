# frozen_string_literal: true

source "https://rubygems.org"

# Specify your gem's dependencies in abacatepay-ruby.gemspec
gemspec

gem "rake", "~> 13.0"

# parallel is a transitive dependency of rubocop. The whole 2.x line requires
# Ruby 3.3, which would make the dev toolchain uninstallable on the oldest Ruby
# this gem supports — even though the gem itself runs fine there, since faraday
# is the only runtime dependency. Pinned so CI genuinely exercises that floor.
gem "parallel", "< 2.0"
