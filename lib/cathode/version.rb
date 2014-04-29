module Cathode
  # A `Version` encapsulates a specific SemVer-compliant version of the API with
  # a set of resources and actions.
  class Version
    include ActionDsl
    include ResourceDsl

    attr_reader :ancestor,
                :version

    @all = []

    class << self
      attr_reader :all

      # Defines a new version.
      # @param version_number [String, Fixnum, Float] A number or string
      #   representing a SemVer-compliant version number. If a `Fixnum` or
      #   `Float` is passed, it will be converted to a string before being
      #   evaluated for SemVer compliance, so passing `1.5` is equivalent to
      #   passing `'1.5.0'`.
      # @param block A block defining the version's resources and actions, and
      #   has access to the methods in the {Cathode::ActionDsl} and {Cathode::ResourceDsl}
      # @return [Version]
      def define(version_number, &block)
        version = Version.find(version_number)
        if version.present?
          version.instance_eval(&block)
        else
          version = self.new(version_number, &block)
        end
        version
      end

      # Polyfills a version number snippet to be SemVer-compliant.
      # @param rough_version [String] A version number snippet such as '1' or
      #   '2.5'
      # @return [String] The SemVer-compliant version number
      def standardize(rough_version)
        version_parts = rough_version.to_s.split '.'
        if version_parts.count < 2
          version_parts << [0, 0]
        elsif version_parts.count < 3
          version_parts << [0]
        end
        version_parts.join '.'
      end

      # Looks up a version by version number.
      # @param version_number [String] The version to find
      # @return [Version, nil] The version if found, `nil` if there is no such
      #   version
      def find(version_number)
        Version.all.detect { |v| v.version == standardize(version_number) }
      rescue ArgumentError
        nil
      end

      # Whether a given version exists
      # @param version_number [String] The version to check
      # @return [Boolean]
      def exists?(version_number)
        find(version_number).present?
      end
    end

    # Initializes a new version.
    # @param version_number [String] A SemVer-compliant version number.
    # @param block A block defining the version's resources and actions, and
    #   has access to the methods in the {Cathode::ActionDsl} and {Cathode::ResourceDsl}
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

    # Whether a resource is defined on the version.
    # @param resource [Symbol] The resource's name
    # @return [Boolean]
    def resource?(resource)
      _resources.names.include? resource.to_sym
    end

    # Whether an action is defined on a resource on the version.
    # @param resource [Symbol] The resource's name
    # @param action [Symbol] The action's name
    # @return [Boolean]
    def action?(resource, action)
      resource = resource.to_sym
      action = action.to_sym

      return false unless resource?(resource)

      _resources.find(resource).actions.names.include? action
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
