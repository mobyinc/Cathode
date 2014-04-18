module Cathode
  class Action
    attr_accessor :strong_params
    attr_reader :action_access_filter,
                :name,
                :resource,
                :action_block,
                :override_block,
                :http_method

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
  end

  module RequiresStrongParams
    def after_resource_initialized
      if strong_params.nil?
        fail UnknownAttributesError, "An attributes block was not specified for `#{name}' action on resource `#{resource}'"
      end

      self
    end
  end

  class IndexAction < Action; end

  class ShowAction < Action; end

  class CreateAction < Action
    include RequiresStrongParams
  end

  class UpdateAction < Action
    include RequiresStrongParams
  end

  class DestroyAction < Action; end

  class CustomAction < Action; end
end
