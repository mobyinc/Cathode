module Cathode
  # Raised when a resource is initialized but there is no constant (ActiveRecord
  # model) that matches it.
  class UnknownResourceError < NameError; end

  # Raised when a nonexistent action is referred to.
  class UnknownActionError < NameError; end

  # Raised when an `attributes` block is not passed in a context that requires
  # one.
  class UnknownAttributesError < NameError; end

  # Raised when a custom action is defined without an HTTP method.
  class RequestMethodMissingError < NameError; end

  # Raised when an ActiveModel association is not present in a context that
  # requires one.
  class MissingAssociationError < NameError; end

  # Raised when an action's behavior has not been defined in a context that
  # requires it.
  class ActionBehaviorMissingError < NameError; end
end
