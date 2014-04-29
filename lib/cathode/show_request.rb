module Cathode
  # Defines the default behavior for a show request.
  class ShowRequest < Request
    # Determine the default action to use depending on the resource. If the
    # resource is singular, set the body to the parent's associated record.
    # Otherwise, lookup the record directly.
    def default_action_block
      proc do
        record = if resource.singular
          parent_model = resource.parent.model.find(parent_resource_id)
          parent_model.send resource.name
        else
          model.find params[:id]
        end
        body record
      end
    end
  end
end
