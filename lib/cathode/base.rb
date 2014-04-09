require 'pry'
require 'cathode/request'
require 'cathode/resource'
require 'cathode/action'
require 'cathode/version'
require 'cathode/railtie'

module Cathode
  class Base
    @@versions = {}

    class << self
      def resource(resource_name, params = nil, &block)
        version 1 do
          resource resource_name, params, &block
        end
      end

      def versions
        @@versions
      end

      def version(version_number, &block)
        version = Version.new(version_number, &block)
        versions[version.version.to_s] = version
      end
    end
  end
end
