module Cathode
  class DestroyRequest < Request
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
