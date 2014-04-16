require 'pry'
require 'cathode/request'
require 'cathode/resource'
require 'cathode/action'
require 'cathode/version'
require 'cathode/railtie'

module Cathode
  class Base
    class << self
      def reset!
        versions.clear
      end

      def define(&block)
        instance_eval &block
      end

      def versions
        Version.all
      end

      def version(version_number, &block)
        Version.new(version_number, &block)
      end

    private

      def resource(resource_name, params = nil, &block)
        version 1 do
          resource resource_name, params, &block
        end
      end
    end
  end
end
