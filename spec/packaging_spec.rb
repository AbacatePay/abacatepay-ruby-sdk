# frozen_string_literal: true

require "rubygems/package"

# The gemspec builds its file list from `git ls-files`, which only sees tracked
# files. A newly added source file that nobody remembered to `git add` is
# silently dropped from the package, and since the manifests require every
# component explicitly, the published gem then raises LoadError on `require`
# while every test here still passes against the working tree.
RSpec.describe "Gem packaging" do
  subject(:packaged_files) { gemspec.files }

  let(:gemspec) { Gem::Specification.load(File.expand_path("../abacatepay-ruby.gemspec", __dir__)) }
  let(:library_files) do
    root = File.expand_path("..", __dir__)
    Dir.glob("lib/**/*.rb", base: root)
  end

  it "loads the gemspec" do
    expect(gemspec).to be_a(Gem::Specification)
  end

  it "ships every file under lib/" do
    expect(library_files - packaged_files).to be_empty
  end

  it "ships the entry point" do
    expect(packaged_files).to include("lib/abacate_pay.rb")
  end

  # Bundler requires a gem by its own name, so `gem "abacatepay-ruby"` in a
  # Gemfile makes Rails call `require "abacatepay-ruby"`. Without a file of that
  # name the SDK never loads, and the first call fails with
  # `undefined method 'configure' for module AbacatePay`.
  it "ships an entry point matching the gem name" do
    expect(packaged_files).to include("lib/abacatepay-ruby.rb")
  end

  it "ships the README" do
    expect(packaged_files).to include("README.md")
  end

  it "ships the licence" do
    expect(packaged_files).to include("LICENSE.txt")
  end

  it "does not ship the spec suite" do
    expect(packaged_files.grep(%r{\Aspec/})).to be_empty
  end

  it "does not ship CI configuration" do
    expect(packaged_files.grep(/\A\.github/)).to be_empty
  end

  it "declares a runtime constraint that excludes the vulnerable faraday range" do
    faraday = gemspec.dependencies.find { |dependency| dependency.name == "faraday" }

    expect(faraday.requirement.satisfied_by?(Gem::Version.new("2.14.2"))).to be false
  end

  it "requires a Ruby version the dependencies can actually run on" do
    expect(gemspec.required_ruby_version.satisfied_by?(Gem::Version.new("2.6.0"))).to be false
  end
end
