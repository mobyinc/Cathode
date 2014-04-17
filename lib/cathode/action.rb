module Cathode
  class Action
    attr_accessor :strong_params
    attr_reader :action_access_filter,
                :name,
                :resource,
                :action_block

    def self.create(action, resource, &block)
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
      klass.new(action, resource, &block)
    end

    def initialize(action, resource, &block)
      @name, @resource = action, resource
      @allowed_subactions = []

      if block_given?
        if [:index, :show, :create, :update, :destroy].include? action
          instance_eval &block
        else 
          @action_block = block
        end
      end
    end

    def perform(context)
      params = context.params

      return { status: :unauthorized } if action_access_filter && !action_access_filter.call

      if @custom_logic
        { custom_logic: @custom_logic }
      end
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

    def override(&custom_logic)
      @custom_logic = custom_logic
    end
  end

  class IndexAction < Action; end

  class ShowAction < Action; end

  class CreateAction < Action
    def default_action_block
      if false & strong_params.nil?
        fail UnknownAttributesError, "An attributes block was not specified for `create' action on resource `#{resource}'"
      end
    end
  end

  class UpdateAction < Action
    def default_action(params)
      if strong_params.nil?
        fail UnknownAttributesError, "An attributes block was not specified for `create' action on resource `#{resource}'"
      end
    end
  end

  class DestroyAction < Action; end

  class CustomAction < Action; end
end
