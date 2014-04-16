require 'semantic'

module Cathode
  class Version
    attr_reader :ancestor,
                :resources,
                :version

    @all = {}

    def initialize(version_number, &block)
      @version = Semantic::Version.new Version.standardize(version_number)
      @resources = {}

      if Version.all.present?
        @ancestor = Version.all.values.last
        @resources = @ancestor.resources.clone
      end

      instance_eval(&block) if block_given?

      Version.all[@version.to_s] = self
    end

    def perform_request(resource, context)
      resources[resource].actions[context.params[:action].to_sym].perform context
    end

    class << self
      attr_reader :all

      def standardize(rough_version)
        version_parts = rough_version.to_s.split '.'
        if version_parts.count < 2
          version_parts << [0, 0]
        elsif version_parts.count < 3
          version_parts << [0]
        end
        version_parts.join '.'
      end

      def perform_request_with_version(version_number, resource, params)
        version = Version.all[standardize(version_number)]

        if version.present?
          version.perform_request resource, params
        else
          { status: 400, body: "Unknown API version: #{version_number}" }
        end
      end
    end

  private

    def resource(resource, params = nil, &block)
      @resources[resource] = Resource.new(resource, params, &block)
    end

    def remove_resource(resources)
      resources = [resources] unless resources.is_a?(Array)

      resources.each do |resource|
        if @resources[resource].nil?
          fail UnknownResourceError, "Unknown resource `#{resource}'"
        end

        @resources.delete(resource)
      end
    end

    def remove_action(resource, actions)
      actions = [actions] unless actions.is_a?(Array)

      actions.each do |action|
        if @resources[resource].actions[action].nil?
          fail UnknownActionError, "Unknown action `#{action}' on resource `#{resource}'"
        end

        @resources[resource].actions.delete action
      end
    end

    alias_method :remove_resources, :remove_resource
    alias_method :remove_actions, :remove_action
  end
end
