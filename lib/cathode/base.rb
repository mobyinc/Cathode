require 'pry'
require 'cathode/engine'
require 'cathode/railtie'
require 'cathode/exceptions'

# Cathode is a gem for creating API boilerplate for resourceful Rails
# applications. It has first-class support for versions, model-backed resources,
# default actions like `create` and `destroy`, and custom actions.
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
  autoload :Query,              'cathode/query'
  autoload :Request,            'cathode/request'
  autoload :Resource,           'cathode/resource'
  autoload :ResourceDsl,        'cathode/resource_dsl'
  autoload :Semantic,           'semantic'
  autoload :ShowRequest,        'cathode/show_request'
  autoload :UpdateRequest,      'cathode/update_request'
  autoload :Version,            'cathode/version'

  # The actions whose default behavior is defined by Cathode.
  DEFAULT_ACTIONS = [:index, :show, :create, :update, :destroy]

  # Holds the top-level Cathode accessors for defining an API.
  class Base
    class << self
      attr_reader :tokens_required

      # Defines an API
      # @param block The API's versions and resources, defined using this
      #   class's `version`, `resources`, and `resource` methods
      def define(&block)
        instance_eval(&block)
      end

      # Lists the collection of versions associated with this API
      # @return [Cathode::ObjectCollection] the collection of versions
      def versions
        Version.all
      end

      # Defines a new version
      # @param version_number [String, Fixnum, Float] A number or string
      #   representing a SemVer-compliant version number. If a `Fixnum` or
      #   `Float` is passed, it will be converted to a string before being
      #   evaluated for SemVer compliance, so passing `1.5` is equivalent to
      #   passing `'1.5.0'`.
      # @param block A block defining the version's resources and actions, and
      #   has access to the methods in the {Cathode::ActionDsl} and {Cathode::ResourceDsl}
      def version(version_number, &block)
        Version.define(version_number, &block)
      end

      # Defines a singular resource on version 1.0.0 of the API
      # @param resource_name [Symbol] The resource's name
      # @param params [Hash] Optional params, e.g. `{ actions: :all }`
      # @param block A block defining the resource's actions and properties, run
      #   inside the context of version 1.0.0 with access to the methods in the
      #   {Cathode::ActionDsl} and {Cathode::ResourceDsl}
      def resource(resource_name, params = nil, &block)
        version 1 do
          resource resource_name, params, &block
        end
      end

      # Defines a plural resource on version 1.0.0 of the API
      # @param resource_name [Symbol] The resource's name
      # @param params [Hash] Optional params, e.g. `{ actions: :all }`
      # @param block A block defining the resource's actions and properties, run
      #   inside the context of version 1.0.0 with access to the methods in the
      #   {Cathode::ActionDsl} and {Cathode::ResourceDsl}
      def resources(resource_name, params = nil, &block)
        version 1 do
          resources resource_name, params, &block
        end
      end

      # Configures this API to require incoming requests to have a valid token
      def require_tokens
        @tokens_required = true
      end

    private

      def reset!
        versions.clear
        @tokens_required = false
      end
    end
  end
end
