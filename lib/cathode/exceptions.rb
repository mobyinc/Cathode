module Cathode
  class UnknownResourceError < NameError; end

  class UnknownActionError < NameError; end

  class UnknownAttributesError < NameError; end

  class RequestMethodMissingError < NameError; end

  class DuplicateResourceError < RuntimeError; end

  class MissingAssociationError < NameError; end
end
