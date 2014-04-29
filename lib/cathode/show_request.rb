module Cathode
  # Defines the default behavior for a show request.
  class ShowRequest < Request
    # Determine the default action to use depending on the resource. If the
    # resource is singular, set the body to the parent's associated record.
    # Otherwise, lookup the record directly.
    def default_action_block
      proc do
        body record
      end
    end
  end
end
