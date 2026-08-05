# frozen_string_literal: true

require_relative "lib/abacate_pay/version"

Gem::Specification.new do |spec|
  spec.name = "abacatepay-ruby"
  spec.version = AbacatePay::VERSION
  spec.authors = ["Matheus Cardoso"]
  spec.email = ["mathuscardoso@gmail.com"]

  spec.summary = "AbacatePay Ruby SDK for you to start receiving payments in seconds"
  spec.description = "The easiest way to integrate your Ruby application with AbacatePay Gateway " \
                     "for payments, subscriptions, PIX transfers, and more."
  spec.homepage = "https://www.abacatepay.com/"
  spec.license = "MIT"
  # faraday 2.x requires Ruby >= 3.0 and the pinned Bundler requires >= 3.2.
  # 3.2 is the oldest version exercised by CI; 2.6 was never actually installable.
  spec.required_ruby_version = ">= 3.2.0"

  # spec.metadata["allowed_push_host"] = "https://rubygems.pkg.github.com/AbacatePay"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/AbacatePay/abacatepay-ruby-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/AbacatePay/abacatepay-ruby-sdk/blob/main/CHANGELOG.md"
  spec.metadata["rubygems_mfa_required"] = "true"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(__dir__) do
    `git ls-files -z`.split("\x0").reject do |f|
      (File.expand_path(f) == __FILE__) ||
        f.start_with?(*%w[bin/ test/ spec/ features/ .git appveyor Gemfile])
    end
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Runtime dependencies
  # >= 2.14.3 excludes CVE-2026-54297 (stack-exhaustion DoS in
  # NestedParamsEncoder). The lockfile only protects this repo — consumers are
  # protected by the constraint here.
  spec.add_dependency "faraday", "~> 2.14", ">= 2.14.3"

  # Development dependencies
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "rspec", "~> 3.12"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "rubocop-rspec", "~> 3.0"
  spec.add_development_dependency "simplecov", "~> 1.0"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
