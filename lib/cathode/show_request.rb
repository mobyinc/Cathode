module Cathode
  class ShowRequest < Request
    def default_action_block
      proc do
        body model.find params[:id]
      end
    end
  end
end
