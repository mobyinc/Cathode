module Cathode
  module ResourceDsl

    def _resources
      @_resources ||= ObjectCollection.new
    end

  protected

    def resources(resource_name, params = nil, &block)
      existing_resource = _resources.find resource_name
      new_resource = Resource.new(resource_name, params, self, &block)

      if existing_resource.present?
        existing_resource.actions.add new_resource.actions.objects
      else
        @_resources << new_resource
      end
    end

    def remove_resource(resources)
      resources = [resources] unless resources.is_a?(Array)

      resources.each do |resource|
        if _resources.find(resource).nil?
          fail UnknownResourceError, "Unknown resource `#{resource}'"
        end

        @_resources.delete(resource)
      end
    end
  end
end
