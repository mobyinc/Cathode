module Cathode
  # An `Action` can be added to a {Resource} or a {Version} and contains the
  # default behavior of that action (if it is a default action), or the override
  # behavior if it is a custom action or an overridden default action.
  class Action
    include ActionDsl

    attr_accessor :strong_params
    attr_reader :action_access_filter,
                :action_block,
                :http_method,
                :name,
                :override_block,
                :resource

    delegate :parent, to: :resource

    class << self
      # Creates an action by initializing the appropriate subclass
      # @param action [Symbol] The action's name
      # @param resource [Resource] The resource the action belongs to
      # @param params [Hash] An optional params hash
      # @param block The action's properties, defined with the {ActionDsl}
      # @return [IndexAction, ShowAction, CreateAction, UpdateAction,
      #   DestroyAction, CustomAction] The subclassed action
      def create(action, resource, params = nil, &block)
        klass = case action
                when :index
                  IndexAction
                when :show
                  ShowAction
                when :create
                  CreateAction
                when :update
                  UpdateAction
                when :destroy
                  DestroyAction
                else
                  CustomAction
                end
        klass.new(action, resource, params, &block)
      end
    end

    # Initializes the action
    # @param action [Symbol] The action's name
    # @param resource [Resource] The resource the action belongs to
    # @param params [Hash] An optional params hash
    # @param block The action's properties, defined with the {ActionDsl}
    def initialize(action, resource, params = {}, &block)
      @name, @resource = action, resource
      @allowed_subactions = []

      if block_given?
        if params[:override]
          override &block
        else
          if [:index, :show, :create, :update, :destroy].include? action
            instance_eval &block
          else 
            @action_block = block
          end
        end
      end

      @http_method = params[:method] if params.present?

      after_initialize if respond_to? :after_initialize
    end

    # Whether a subaction is permitted
    # @param subaction [Symbol] The subaction's name
    # @return [Boolean]
    def allowed?(subaction)
      @allowed_subactions.include? subaction
    end

  private

    def model
      resource.to_s.camelize.singularize.constantize
    end

    def access_filter(&filter)
      @action_access_filter = filter
    end

    def allows(*subactions)
      @allowed_subactions = subactions
    end

    def replace(&block)
      @action_block = block
    end

    def override(&block)
      @override_block = block
    end

    def overridden?
      override_block.present?
    end

    def after_resource_initialized
      self
    end

    # Requires that the action has an attributes block defined or one is defined
    # at the resource level
    module RequiresStrongParams
      # Raises an error if there is no attributes block defined
      def after_resource_initialized
        if strong_params.nil?
          if resource.strong_params.present?
            @strong_params = resource.strong_params
          else
            fail UnknownAttributesError, "An attributes block was not specified for `#{name}' action on resource `#{resource.name}'"
          end
        end

        super
      end
    end

    # Raises an error if the action was defined on a resource whose parent
    # doesn't have an association to the resource
    module RequiresAssociation
      # Defines the possible associations as `:resources` (`has_many`) or
      # `:resource` (`has_one`)
      def association_keys
        [
          resource.name.to_s.singularize.to_sym,
          resource.name.to_s.pluralize.to_sym
        ]
      end

      # Determines whether an expected association is present.
      def after_resource_initialized
        if parent.present? && !overridden?
          reflections = parent.model.reflections

          if association_keys.map { |key| reflections.include?(key) }.none?
            raise MissingAssociationError, error_message
          end
        end

        super
      end
    end

    # Raises an error if the action was defined on a resource whose parent
    # doesn't have a `has_one` association to the resource
    module RequiresHasOneAssociation
      include RequiresAssociation

      # Defines the possible associations as `:resource` (`has_one`)
      def association_keys
        [resource.name.to_s.singularize.to_sym]
      end

      # Provides an error message to display if the association is missing.
      def error_message
        "Can't use default :#{name} action on `#{parent.name}' without a has_one `#{resource.name.to_s.singularize}' association"
      end
    end

    # Raises an error if the action was defined on a resource whose parent
    # doesn't have a `has_many` association to the resource
    module RequiresHasManyAssociation
      include RequiresAssociation

      # Defines the possible associations as `:resources` (`has_many`).
      def association_keys
        [resource.name.to_s.pluralize.to_sym]
      end

      # Provides an error message to display if the association is missing.
      def error_message
        "Can't use default :#{name} action on `#{parent.name}' without a has_many or has_and_belongs_to_many `#{resource.name.to_s.singularize}' association"
      end
    end

    # Requires the resource to define custom action behavior if it is a singular
    # resource.
    module RequiresCustomActionForSingular
      # Raises an error if the resource is singular and attempting to use the
      # default action without a parent resource
      def after_resource_initialized
        if resource.singular && !overridden? && resource.parent.nil?
          raise Cathode::ActionBehaviorMissingError,
            "Can't use default :#{name} action on singular resource `#{resource.name}'"
        end

        super
      end
    end
  end

  # Provides additional behavior for index actions.
  class IndexAction < Action
    include RequiresCustomActionForSingular
    include RequiresHasManyAssociation
  end

  # Provides additional behavior for show actions.
  class ShowAction < Action
    include RequiresCustomActionForSingular
    include RequiresHasOneAssociation
  end

  # Provides additional behavior for create actions.
  class CreateAction < Action
    include RequiresCustomActionForSingular
    include RequiresStrongParams
    include RequiresAssociation
  end

  # Provides additional behavior for update actions.
  class UpdateAction < Action
    include RequiresCustomActionForSingular
    include RequiresStrongParams
    include RequiresHasOneAssociation
  end

  # Provides additional behavior for destroy actions.
  class DestroyAction < Action
    include RequiresCustomActionForSingular
    include RequiresHasOneAssociation
  end

  # Provides additional behavior for non-default actions.
  class CustomAction < Action
    # Raises an error if the action was defined without an HTTP method
    def after_initialize
      if http_method.nil?
        raise RequestMethodMissingError, "You must specify an HTTP method (get, put, post, delete) for action `#{@name}'"
      end
    end
  end
end
