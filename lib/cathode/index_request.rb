module Cathode
  class IndexRequest < Request
    def model
      if @resource_tree.size > 1
        parent_model_id = params["#{@resource_tree.first.name.to_s.singularize}_id"]
        model = @resource_tree.first.model.find(parent_model_id)
        @resource_tree.drop(1).each do |resource|
          model = model.send resource.name
        end
        model
      else
        super.all
      end
    end

    def default_action_block
      proc do
        all_records = model

        if allowed?(:paging) && params[:page]
          page = params[:page]
          per_page = params[:per_page] || 10
          lower_bound = (per_page - 1) * page
          upper_bound = lower_bound + per_page - 1

          body all_records[lower_bound..upper_bound]
        else
          body all_records
        end
      end
    end
  end
end
