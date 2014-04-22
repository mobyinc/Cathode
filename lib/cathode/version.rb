require 'semantic'

module Cathode
  class Version
    attr_reader :ancestor,
                :resources,
                :version

    @all = []

    def initialize(version_number, &block)
      @version = Semantic::Version.new Version.standardize(version_number)

      @resources = ObjectCollection.new

      if Version.all.present?
        @ancestor = Version.all.last
        @resources = @ancestor.resources.clone
      end

      instance_eval(&block) if block_given?

      Version.all << self
    end

    def resource?(resource)
      @resources.names.include? resource.to_sym
    end

    def action?(resource, action)
      resource = resource.to_sym
      action = action.to_sym

      return false unless resource?(resource)

      @resources.find(resource).actions.names.include? action
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

      def find(version_number)
        Version.all.detect { |v| v.version == standardize(version_number) }
      rescue ArgumentError
        return nil
      end

      def exists?(version_number)
        find(version_number).present?
      end
    end

  private

    def resource(resource, params = nil, &block)
      if resources.names.include? resource
      #  fail DuplicateResourceError, "Resource `#{resource}' already defined on version #{version}"
      end

      @resources << Resource.new(resource, params, &block)
    end

    def remove_resource(resources)
      resources = [resources] unless resources.is_a?(Array)

      resources.each do |resource|
        if @resources.find(resource).nil?
          fail UnknownResourceError, "Unknown resource `#{resource}'"
        end

        @resources.delete(resource)
      end
    end

    def remove_action(resource, actions)
      actions = [actions] unless actions.is_a?(Array)

      actions.each do |action|
        if @resources.find(resource).actions.find(action).nil?
          fail UnknownActionError, "Unknown action `#{action}' on resource `#{resource}'"
        end

        @resources.find(resource).actions.delete action
      end
    end

    alias_method :remove_resources, :remove_resource
    alias_method :remove_actions, :remove_action
  end
end
