module Cathode
  # Defines the default behavior for a create request.
  class CreateRequest < Request
    # Sets the default action to create a new resource. If the resource is
    # singular, sets the parent resource `id` as well.
    def default_action_block
      proc do
        begin
          create_params = instance_eval(&@strong_params)
          if resource.singular
            create_params["#{parent_resource_name}_id"] = parent_resource_id
          end
          body model.create(create_params)
        rescue ActionController::ParameterMissing => error
          body error.message
          status :bad_request
        end
      end
    end
  end
end
