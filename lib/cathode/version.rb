require 'semantic'

module Cathode
  class Version
    attr_reader :ancestor,
                :resources,
                :version

    @@all = {}

    def initialize(version_number, &block)
      @version = Semantic::Version.new Version.standardize(version_number)
      @resources = {}

      if Version.all.present?
        @ancestor = Version.all.values.last
        @resources = @ancestor.resources.clone
      end

      self.instance_eval &block if block_given?

      Version.all[@version.to_s] = self
    end

    def perform_request(resource, params)
      resources[resource].actions[params[:action].to_sym].perform params
    end

    class << self
      def all
        @@all
      end

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

    def remove_resource(resource)
      @resources.delete(resource)
    end
  end
end
