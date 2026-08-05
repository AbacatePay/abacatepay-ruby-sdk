# frozen_string_literal: true

module AbacatePay
  # A page of results plus the cursor needed to fetch the next one.
  #
  # List endpoints return at most 100 items and report whether more exist. The
  # SDK used to return a bare Array and drop that metadata, which made it
  # impossible to page past the first 100 records.
  #
  # Behaves like an Array everywhere an Array was returned before, so existing
  # code keeps working:
  #
  #   customers = AbacatePay.customers.list
  #   customers.each { |c| puts c.id }   # Enumerable
  #   customers.size                     # items on this page
  #   customers.has_more?                # is there another page?
  #
  # To walk every page without handling cursors:
  #
  #   AbacatePay.customers.each_page { |page| page.each { |c| puts c.id } }
  #   AbacatePay.customers.auto_paging_each { |customer| puts customer.id }
  class Collection
    include Enumerable

    # @return [Array] The items on this page
    attr_reader :items

    # @return [String, nil] Cursor for the next page, passed back as `after`
    attr_reader :next_cursor

    # @return [String, nil] Cursor for the previous page, passed back as `before`
    attr_reader :before_cursor

    # @param items [Array] The items on this page
    # @param pagination [Hash, nil] The raw `pagination` object from the API
    def initialize(items, pagination = nil)
      @items = Array(items)
      pagination = {} unless pagination.is_a?(Hash)
      @has_more = pagination["hasMore"] || false
      @next_cursor = pagination["next"]
      @before_cursor = pagination["before"]
    end

    # @yield [Object] Each item on this page
    # @return [Enumerator, self]
    def each(&)
      return to_enum(:each) unless block_given?

      items.each(&)
      self
    end

    # Whether the API reported further pages after this one.
    #
    # @return [Boolean]
    def has_more?
      @has_more
    end

    # @return [Integer] Number of items on this page
    def size
      items.size
    end
    alias length size
    alias count size

    # @return [Boolean]
    def empty?
      items.empty?
    end

    # @param index [Integer, Range] Index into this page
    # @return [Object, Array, nil]
    def [](index)
      items[index]
    end

    # @return [Array] A plain Array copy of this page
    def to_a
      items.dup
    end
    alias to_ary to_a

    # Returns a new Collection with different items and the same cursor.
    # Used to turn raw hashes into resources without losing pagination.
    #
    # @param new_items [Array] The mapped items
    # @return [Collection]
    def with_items(new_items)
      self.class.new(new_items, "hasMore" => has_more?, "next" => next_cursor, "before" => before_cursor)
    end

    # @return [String]
    def inspect
      "#<#{self.class.name} size=#{size} has_more=#{has_more?} next=#{next_cursor.inspect}>"
    end
  end
end
