require 'semantic'
require 'deep_clone'

module Cathode
  class Version
    include ActionDsl

    attr_reader :ancestor,
                :resources,
                :version

    @all = []

    class << self
      def define(version_number, &block)
        version = Version.find(version_number)
        if version.present?
          version.instance_eval(&block)
        else
          version = self.new(version_number, &block)
        end
        version
      end
    end

    def initialize(version_number, &block)
      @version = Semantic::Version.new Version.standardize(version_number)

      @resources = ObjectCollection.new

      if Version.all.present?
        @ancestor = Version.all.last
        @resources = DeepClone.clone @ancestor.resources
        actions.add ancestor.actions.objects
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
        nil
      end

      def exists?(version_number)
        find(version_number).present?
      end
    end

  private

    def resource(resource_name, params = nil, &block)
      existing_resource = resources.find resource_name
      new_resource = Resource.new(resource_name, params, &block)

      if existing_resource.present?
        existing_resource.actions.add new_resource.actions.objects
      else
        @resources << new_resource
      end
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

    def remove_action(*args)
      if args.last.is_a?(Hash)
        resource_name = args.last[:from]
        resource = @resources.find(resource_name)
        actions_to_remove = args.take args.size - 1

        if resource.nil?
          fail UnknownResourceError, "Unknown resource `#{resource_name}' on ancestor version #{ancestor.version}"
        end

        actions_to_remove.each do |action|
          if resource.actions.find(action).nil?
            fail UnknownActionError, "Unknown action `#{action}' on resource `#{resource_name}'"
          end

          resource.actions.delete action
        end
      else
        args.each do |action|
          if actions.find(action).nil?
            fail UnknownActionError, "Unknown action `#{action}' on ancestor version #{ancestor.version}"
          end

          actions.delete action
        end
      end
    end

    alias_method :remove_resources, :remove_resource
    alias_method :remove_actions, :remove_action
  end
end
