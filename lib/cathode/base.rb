require 'pry'
require 'cathode/exceptions'
require 'cathode/railtie'

module Cathode
  autoload :Action,             'cathode/action'
  autoload :ActionDsl,          'cathode/action_dsl'
  autoload :CreateRequest,      'cathode/create_request'
  autoload :CustomRequest,      'cathode/custom_request'
  autoload :Debug,              'cathode/debug'
  autoload :DeepClone,          'deep_clone'
  autoload :DestroyRequest,     'cathode/destroy_request'
  autoload :IndexRequest,       'cathode/index_request'
  autoload :ObjectCollection,   'cathode/object_collection'
  autoload :Request,            'cathode/request'
  autoload :Resource,           'cathode/resource'
  autoload :ResourceDsl,        'cathode/resource_dsl'
  autoload :Semantic,           'semantic'
  autoload :ShowRequest,        'cathode/show_request'
  autoload :UpdateRequest,      'cathode/update_request'
  autoload :Version,            'cathode/version'

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

      def resources(resource_name, params = nil, &block)
        version 1 do
          resources resource_name, params, &block
        end
      end
    end
  end
end
