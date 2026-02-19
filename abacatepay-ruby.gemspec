# frozen_string_literal: true

require_relative "lib/abacate_pay/version"

Gem::Specification.new do |spec|
  spec.name = "abacatepay-ruby"
  spec.version = AbacatePay::VERSION
  spec.authors = ["Matheus Cardoso"]
  spec.email = ["mathuscardoso@gmail.com"]

  spec.summary = "AbacatePay Ruby on Rails SDK for you to start receiving payments in seconds"
  spec.description = "The easiest way to integrate your Ruby on Rails SDK base code to AbacatePay Gateway with support to coroutines."
  spec.homepage = "https://www.abacatepay.com/"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  # spec.metadata["allowed_push_host"] = "https://github.com/AbacatePay/abacatepay-ruby-sdk"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/AbacatePay/abacatepay-ruby-sdk"
  spec.metadata["changelog_uri"] = "https://github.com/AbacatePay/abacatepay-ruby-sdk/blob/main/CHANGELOG.md"

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
  spec.add_dependency "rails", "~> 7.0", ">= 7.0.0"
  spec.add_dependency "faraday", "~> 2.9"

  # Development dependencies
  spec.add_development_dependency "rspec-rails", "~> 6.0"
  spec.add_development_dependency "rubocop", "~> 1.57"
  spec.add_development_dependency "rubocop-rails", "~> 2.22"
  spec.add_development_dependency "rubocop-rspec", "~> 2.25"
  spec.add_development_dependency "simplecov", "~> 0.22"

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
