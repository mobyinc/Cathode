module Cathode
  # Defines the default behavior for an update request.
  class UpdateRequest < Request
    # Sets the default action to update a resource. If the resource is
    # singular, updates the parent's associated resource. Otherwise, updates the
    # resource directly.
    def default_action_block
      proc do
        begin
          record = if resource.singular
                    parent_model = resource.parent.model.find(parent_resource_id)
                    parent_model.send resource.name
                  else
                    record = model.find(params[:id])
                  end

          record.update(instance_eval(&@strong_params))
          body record.reload
        rescue ActionController::ParameterMissing => error
          body error.message
          status :bad_request
        end
      end
    end
  end
end
