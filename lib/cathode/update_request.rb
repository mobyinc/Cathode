module Cathode
  class UpdateRequest < Request
    def default_action_block
      proc do
        begin
          record = model.find(params[:id])
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
