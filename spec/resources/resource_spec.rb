# frozen_string_literal: true

RSpec.describe AbacatePay::Resources::Resource do
  # Concrete subclass used to exercise the base class methods
  let(:test_class) do
    Class.new(described_class) do
      attr_accessor :name, :some_value, :created_at

      def initialize(data = {})
        fill(data)
      end

      private

      def process_value(_property, value)
        value
      end

      public

      def to_hash
        super
      end
    end
  end

  let(:instance) { test_class.new }

  # ── camel_to_snake ────────────────────────────────────────────────────────────

  describe "#camel_to_snake" do
    it "converts simple camelCase" do
      expect(instance.send(:camel_to_snake, "camelCase")).to eq("camel_case")
    end

    it "converts multi-word camelCase" do
      expect(instance.send(:camel_to_snake, "returnUrl")).to eq("return_url")
    end

    it "converts consecutive capitals correctly" do
      expect(instance.send(:camel_to_snake, "completionURL")).to eq("completion_url")
    end

    it "leaves already snake_case strings unchanged" do
      expect(instance.send(:camel_to_snake, "snake_case")).to eq("snake_case")
    end

    it "leaves a single lowercase word unchanged" do
      expect(instance.send(:camel_to_snake, "name")).to eq("name")
    end

    it "accepts symbols by converting them to string first" do
      expect(instance.send(:camel_to_snake, :someKey)).to eq("some_key")
    end
  end

  # ── snake_to_camel ────────────────────────────────────────────────────────────

  describe "#snake_to_camel" do
    it "converts snake_case to camelCase" do
      expect(instance.send(:snake_to_camel, "snake_case")).to eq("snakeCase")
    end

    it "converts multi-segment snake_case" do
      expect(instance.send(:snake_to_camel, "return_url")).to eq("returnUrl")
    end

    it "leaves a single word unchanged" do
      expect(instance.send(:snake_to_camel, "name")).to eq("name")
    end
  end

  # ── fill ─────────────────────────────────────────────────────────────────────

  describe "#fill" do
    it "populates attributes from a camelCase hash" do
      obj = test_class.new("someValue" => "hello")
      expect(obj.some_value).to eq("hello")
    end

    it "populates multiple attributes at once" do
      obj = test_class.new("name" => "John", "someValue" => 42)
      expect(obj.name).to eq("John")
      expect(obj.some_value).to eq(42)
    end

    it "ignores unknown keys" do
      expect { test_class.new("unknownKey" => "value") }.not_to raise_error
    end

    it "sets attributes to nil when nil values are provided" do
      obj = test_class.new("name" => nil)
      expect(obj.name).to be_nil
    end
  end

  # ── initialize_date_time ──────────────────────────────────────────────────────

  describe "#initialize_date_time" do
    it "returns nil for nil input" do
      expect(instance.send(:initialize_date_time, nil)).to be_nil
    end

    it "returns nil for an empty string" do
      expect(instance.send(:initialize_date_time, "")).to be_nil
    end

    it "parses an ISO 8601 string into a DateTime" do
      result = instance.send(:initialize_date_time, "2024-06-15T10:30:00Z")
      expect(result).to be_a(DateTime)
      expect(result.year).to eq(2024)
      expect(result.month).to eq(6)
      expect(result.day).to eq(15)
    end

    it "clones an existing DateTime instead of returning the same object" do
      original = DateTime.now
      result = instance.send(:initialize_date_time, original)
      expect(result).to be_a(DateTime)
      expect(result).not_to be(original)
    end

    it "raises ArgumentError for an invalid date string" do
      expect { instance.send(:initialize_date_time, "not-a-date") }
        .to raise_error(ArgumentError, /Invalid datetime/)
    end
  end

  # ── initialize_enum ───────────────────────────────────────────────────────────

  describe "#initialize_enum" do
    let(:enum_class) { AbacatePay::Enums::Billings::Statuses }

    it "returns nil for nil input" do
      expect(instance.send(:initialize_enum, enum_class, nil)).to be_nil
    end

    it "returns nil for an empty string" do
      expect(instance.send(:initialize_enum, enum_class, "")).to be_nil
    end

    it "returns the string value for a valid enum" do
      expect(instance.send(:initialize_enum, enum_class, "PAID")).to eq("PAID")
    end

    it "raises ArgumentError for an invalid enum value" do
      expect { instance.send(:initialize_enum, enum_class, "INVALID") }
        .to raise_error(ArgumentError)
    end
  end

  # ── initialize_resource ───────────────────────────────────────────────────────

  describe "#initialize_resource" do
    let(:resource_class) { AbacatePay::Resources::Customers }

    it "returns nil for nil input" do
      expect(instance.send(:initialize_resource, resource_class, nil)).to be_nil
    end

    it "returns nil for an empty hash" do
      expect(instance.send(:initialize_resource, resource_class, {})).to be_nil
    end

    it "builds a resource instance from a hash" do
      result = instance.send(:initialize_resource, resource_class, { "id" => "cust-1" })
      expect(result).to be_a(resource_class)
      expect(result.id).to eq("cust-1")
    end

    it "clones an existing resource of the same class" do
      original = resource_class.new({ "id" => "cust-1" })
      result = instance.send(:initialize_resource, resource_class, original)
      expect(result).to be_a(resource_class)
      expect(result).not_to be(original)
    end

    it "raises ArgumentError for a non-Hash, non-resource value" do
      expect { instance.send(:initialize_resource, resource_class, "invalid") }
        .to raise_error(ArgumentError, /Invalid resource value/)
    end
  end

  # ── to_hash ───────────────────────────────────────────────────────────────────

  describe "#to_hash" do
    it "converts populated attributes to a camelCase hash" do
      obj = test_class.new("name" => "Alice", "someValue" => 99)
      hash = obj.to_hash
      expect(hash).to include("name" => "Alice", "someValue" => 99)
    end

    it "omits nil values" do
      obj = test_class.new("name" => "Alice")
      expect(obj.to_hash.values).not_to include(nil)
    end

    it "serializes DateTime values to ISO 8601" do
      obj = test_class.new
      obj.created_at = DateTime.new(2024, 1, 15, 10, 30, 0)
      hash = obj.to_hash
      expect(hash["createdAt"]).to match(/2024-01-15/)
    end
  end
end
