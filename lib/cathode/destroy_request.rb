module Cathode
  # Defines the default behavior for a destroy request.
  class DestroyRequest < Request
    # Sets the default action to destroy a resource. If the resource is
    # singular, destroys the parent's associated resource. Otherwise, destroys
    # the resource directly.
    def default_action_block
      proc do
        record = if resource.singular
                  parent_model = resource.parent.model.find(parent_resource_id)
                  parent_model.send resource.name
                else
                  model.find(params[:id])
                end
        record.destroy
      end
    end
  end
end
