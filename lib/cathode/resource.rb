module Cathode
  class Resource
    attr_reader :actions,
                :name

    def initialize(resource_name, params = nil, &block)
      require_resource_constant! resource_name

      params ||= { actions: [] }

      @name = resource_name

      controller_name = "#{resource_name.to_s.camelize}Controller"
      unless Cathode.const_defined? controller_name
        Cathode.const_set controller_name, Class.new(Cathode::BaseController)
      end

      @actions = {}
      actions_to_add = params[:actions] == [:all] ? [:index, :show, :create, :update, :destroy] : params[:actions]
      actions_to_add.each do |action_name|
        action action_name
      end
      instance_eval(&block) if block_given?

      @actions.each do |action_name, action|
        action.after_resource_initialized if action.respond_to? :after_resource_initialized
      end
    end

  private

    def action(action, &block)
      @actions[action] = Action.create(action, @name, &block)
    end

    def attributes(&block)
      unless @actions[:create] || @actions[:update]
        fail UnknownActionError, 'An attributes block was specified without a :create or :update action'
      end

      @actions[:create].strong_params = block if @actions[:create].present?
      @actions[:update].strong_params = block if @actions[:update].present?
    end

    def override_action(action, &block)
      action action do
        override(&block)
      end
    end

    def require_resource_constant!(resource_name)
      if resource_name.to_s.singularize.camelize.safe_constantize.nil?
        fail UnknownResourceError
      end
    end
  end
end
