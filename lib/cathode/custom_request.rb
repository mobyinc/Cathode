module Cathode
  # Holds a custom (non-`[index, show, create, update, delete]`) request. Custom
  # requests have no default actions, so this is a no-op.
  class CustomRequest < Request; end
end
