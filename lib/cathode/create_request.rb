module Cathode
  class CreateRequest < Request
    def default_action_block
      proc do
        begin
          body model.create(instance_eval(&@strong_params))
        rescue ActionController::ParameterMissing => error
          body error.message
          status :bad_request
        end
      end
    end
  end
end
