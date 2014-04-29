module Cathode
  # Provides an enumerable interface for arrays of objects.
  class ObjectCollection
    attr_accessor :objects

    delegate :each, to: :objects
    delegate :select, to: :objects

    def initialize
      @objects = []
    end

    # Look up an object by its `name` property.
    # @param name [Symbol] The object's name
    # @return [Object]
    def find(name)
      objects.detect { |o| o.name == name }
    end

    # An array of all the `name` properties in this object.
    # @return [Array]
    def names
      objects.map(&:name)
    end

    # Adds a new object to the collection.
    # @param items [Object, Array] A single object or an array of objects to add
    # @return [ObjectCollection] self
    def add(items)
      items = [items] unless items.is_a?(Array)
      self.objects += items
      self
    end

    # Delets an object from the collection by name.
    # @param name [Symbol] The name of the object to remove
    # @return [ObjectCollection] self
    def delete(name)
      objects.delete find(name)
      self
    end

    # Forwards all missing methods to the `objects` array stored in this
    # collection.
    def method_missing(method, args)
      objects.send method, args
    end
  end
end
