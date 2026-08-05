# frozen_string_literal: true

RSpec.describe AbacatePay::Collection do
  subject(:collection) do
    described_class.new(%w[a b c], { "hasMore" => true, "next" => "cur_9", "before" => "cur_1" })
  end

  describe "pagination metadata" do
    it "exposes hasMore" do
      expect(collection.has_more?).to be true
    end

    it "exposes the next cursor" do
      expect(collection.next_cursor).to eq("cur_9")
    end

    it "exposes the before cursor" do
      expect(collection.before_cursor).to eq("cur_1")
    end

    it "defaults hasMore to false when the API sends no pagination" do
      expect(described_class.new(%w[a]).has_more?).to be false
    end

    it "tolerates a non-Hash pagination value" do
      expect(described_class.new(%w[a], "unexpected").has_more?).to be false
    end
  end

  # List endpoints returned a bare Array before pagination existed. Nothing
  # that worked then may break now.
  describe "Array compatibility" do
    it "is Enumerable" do
      expect(collection).to be_a(Enumerable)
    end

    it "supports each" do
      seen = collection.each_with_object([]) { |item, acc| acc << item }
      expect(seen).to eq(%w[a b c])
    end

    it "supports map" do
      expect(collection.map(&:upcase)).to eq(%w[A B C])
    end

    it "supports select" do
      expect(collection.select { |item| item > "a" }).to eq(%w[b c])
    end

    it "supports first" do
      expect(collection.first).to eq("a")
    end

    it "supports index access" do
      expect(collection[1]).to eq("b")
    end

    it "reports size" do
      expect(collection.size).to eq(3)
    end

    it "aliases length" do
      expect(collection.length).to eq(3)
    end

    it "reports empty?" do
      expect(described_class.new([])).to be_empty
    end

    it "converts to a plain Array" do
      expect(collection.to_a).to eq(%w[a b c])
    end

    # Splat and Array() rely on to_ary.
    it "implicitly converts via Array()" do
      expect(Array(collection)).to eq(%w[a b c])
    end

    it "returns an Enumerator from each without a block" do
      expect(collection.each).to be_a(Enumerator)
    end
  end

  describe "#with_items" do
    it "keeps the cursor while replacing the items" do
      mapped = collection.with_items(%w[x y])

      expect(mapped.next_cursor).to eq("cur_9")
    end

    it "keeps hasMore" do
      expect(collection.with_items(%w[x]).has_more?).to be true
    end

    it "carries the new items" do
      expect(collection.with_items(%w[x y]).to_a).to eq(%w[x y])
    end
  end

  describe "#inspect" do
    it "summarises without dumping every item" do
      expect(collection.inspect).to eq('#<AbacatePay::Collection size=3 has_more=true next="cur_9">')
    end
  end
end
