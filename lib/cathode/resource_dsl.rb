module Cathode
  module ResourceDsl

    def resources
      @resources ||= ObjectCollection.new
    end

  protected

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
  end
end