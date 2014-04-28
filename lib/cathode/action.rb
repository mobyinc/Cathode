module Cathode
  class Action
    attr_accessor :strong_params
    attr_reader :action_access_filter,
                :name,
                :resource,
                :action_block,
                :override_block,
                :http_method

    delegate :parent, to: :resource

    def self.create(action, resource, params = nil, &block)
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

    def attributes(&strong_params_block)
      @strong_params = strong_params_block
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
  end

  module RequiresStrongParams
    def after_resource_initialized
      if strong_params.nil?
        fail UnknownAttributesError, "An attributes block was not specified for `#{name}' action on resource `#{resource.name}'"
      end

      super
    end
  end

  module RequiresAssociation
    def association_keys
      [
        resource.name.to_s.singularize.to_sym,
        resource.name.to_s.pluralize.to_sym
      ]
    end

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

  module RequiresHasOneAssociation
    include RequiresAssociation

    def association_keys
      [resource.name.to_s.singularize.to_sym]
    end

    def error_message
      "Can't use default :#{name} action on `#{parent.name}' without a has_one `#{resource.name.to_s.singularize}' association"
    end
  end

  module RequiresHasManyAssociation
    include RequiresAssociation

    def association_keys
      [resource.name.to_s.pluralize.to_sym]
    end

    def error_message
      "Can't use default :#{name} action on `#{parent.name}' without a has_many or has_and_belongs_to_many `#{resource.name.to_s.singularize}' association"
    end
  end

  module RequiresCustomActionForSingular
    def after_resource_initialized
      if resource.singular && !overridden? && resource.parent.nil?
        raise Cathode::ActionBehaviorMissingError,
          "Can't use default :#{name} action on singular resource `#{resource.name}'"
      end

      super
    end
  end

  class IndexAction < Action
    include RequiresCustomActionForSingular
    include RequiresHasManyAssociation
  end

  class ShowAction < Action
    include RequiresCustomActionForSingular
    include RequiresHasOneAssociation
  end

  class CreateAction < Action
    include RequiresCustomActionForSingular
    include RequiresStrongParams
    include RequiresAssociation
  end

  class UpdateAction < Action
    include RequiresCustomActionForSingular
    include RequiresStrongParams
    include RequiresHasOneAssociation
  end

  class DestroyAction < Action
    include RequiresCustomActionForSingular
    include RequiresHasOneAssociation
  end

  class CustomAction < Action
    def after_initialize
      if http_method.nil?
        raise RequestMethodMissingError, "You must specify an HTTP method (get, put, post, delete) for action `#{@name}'"
      end
    end
  end
end
