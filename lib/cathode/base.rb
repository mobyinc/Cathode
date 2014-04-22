require 'pry'
require 'cathode/request'
require 'cathode/index_request'
require 'cathode/show_request'
require 'cathode/create_request'
require 'cathode/update_request'
require 'cathode/destroy_request'
require 'cathode/custom_request'
require 'cathode/exceptions'
require 'cathode/object_collection'
require 'cathode/action_dsl'
require 'cathode/resource'
require 'cathode/action'
require 'cathode/version'
require 'cathode/railtie'
require 'cathode/debug'

module Cathode
  DEFAULT_ACTIONS = [:index, :show, :create, :update, :destroy]

  class Base
    class << self
      def reset!
        versions.clear
      end

      def define(&block)
        instance_eval(&block)
      end

      def versions
        Version.all
      end

      def version(version_number, &block)
        Version.define(version_number, &block)
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
