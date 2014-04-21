module Cathode
  class IndexRequest < Request
    def default_action_block
      proc do
        all_records = model.all

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
