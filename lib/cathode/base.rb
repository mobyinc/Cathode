require 'pry'
require 'cathode/resource'
require 'cathode/action'

module Cathode
  class Base
    class << self
      def resource(resource_name, params)
        Resource.new(resource_name, params)
      end
    end
  end
end
