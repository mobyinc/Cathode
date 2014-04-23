module Cathode
  class Version
    include ActionDsl
    include ResourceDsl

    attr_reader :ancestor,
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

      if Version.all.present?
        @ancestor = Version.all.last
        @_resources = DeepClone.clone @ancestor._resources
        actions.add ancestor.actions.objects
      end

      instance_eval(&block) if block_given?

      Version.all << self
    end

    def resource?(resource)
      _resources.names.include? resource.to_sym
    end

    def action?(resource, action)
      resource = resource.to_sym
      action = action.to_sym

      return false unless resource?(resource)

      _resources.find(resource).actions.names.include? action
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

    def remove_action(*args)
      if args.last.is_a?(Hash)
        resource_name = args.last[:from]
        resource = @_resources.find(resource_name)
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
