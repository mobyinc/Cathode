module Cathode
  # Holds the domain-specific language (DSL) for describing resources.
  module ResourceDsl
    # Lists all the resources; initializes an empty `ObjectCollection` if there
    # aren't any yet
    # @return [Array] The resources
    def _resources
      @_resources ||= ObjectCollection.new
    end

  protected

    def resources(resource_name, params = {}, &block)
      add_resource resource_name, false, params, &block
    end

    def resource(resource_name, params = {}, &block)
      add_resource resource_name, true, params, &block
    end

    def add_resource(resource_name, singular, params, &block)
      params ||= {}
      params = params.merge(singular: singular)
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
