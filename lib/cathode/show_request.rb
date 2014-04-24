module Cathode
  class ShowRequest < Request
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
