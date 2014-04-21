module Cathode
  class DestroyRequest < Request
    def default_action_block
      proc do
        model.find(params[:id]).destroy
      end
    end
  end
end
