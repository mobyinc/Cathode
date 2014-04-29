module Cathode
  # Defines the default behavior for a destroy request.
  class DestroyRequest < Request
    # Sets the default action to destroy a resource. If the resource is
    # singular, destroys the parent's associated resource. Otherwise, destroys
    # the resource directly.
    def default_action_block
      proc do
        record.destroy
      end
    end
  end
end
