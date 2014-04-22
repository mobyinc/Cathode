module Cathode
  class ObjectCollection
    attr_accessor :objects

    delegate :each, to: :objects
    delegate :select, to: :objects

    def initialize
      @objects = []
    end

    def find(name)
      objects.detect { |o| o.name == name }
    end

    def names
      objects.map(&:name)
    end

    def add(items)
      items = [items] unless items.is_a?(Array)
      self.objects += items
      self
    end

    def delete(name)
      objects.delete find(name)
      self
    end

    def method_missing(method, args)
      objects.send method, args
    end
  end
end
