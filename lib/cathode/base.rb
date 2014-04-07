require 'pry'
require 'cathode/request'
require 'cathode/resource'
require 'cathode/action'

module Cathode
  class Base
    attr_reader :resources

    @@resources = {}

    class << self
      def resources
        @@resources
      end

      def resource(resource_name, params = nil, &block)
        resources[resource_name] = Resource.new(resource_name, params, &block)
      end
    end
  end
end
