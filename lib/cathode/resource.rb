module Cathode
  class Resource
    DEFAULT_ACTIONS = [:index, :show, :create, :update, :destroy]

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
      actions_to_add = params[:actions] == [:all] ? DEFAULT_ACTIONS : params[:actions]
      actions_to_add.each do |action_name|
        action action_name
      end
      instance_eval(&block) if block_given?

      @actions.each do |action_name, action|
        action.after_resource_initialized if action.respond_to? :after_resource_initialized
      end
    end

    def default_actions
      actions.select { |key, val| DEFAULT_ACTIONS.include? key }
    end

    def custom_actions
      actions.select { |key, val| !DEFAULT_ACTIONS.include?(key) }
    end

  private

    def action(action, params = {}, &block)
      @actions[action] = Action.create(action, @name, params, &block)
    end

    def get(action_name, &block)
      action action_name, method: :get, &block
    end

    def post(action_name, &block)
      action action_name, method: :post, &block
    end

    def put(action_name, &block)
      action action_name, method: :put, &block
    end

    def delete(action_name, &block)
      action action_name, method: :delete, &block
    end

    def attributes(&block)
      unless @actions[:create] || @actions[:update]
        fail UnknownActionError, 'An attributes block was specified without a :create or :update action'
      end

      @actions[:create].strong_params = block if @actions[:create].present?
      @actions[:update].strong_params = block if @actions[:update].present?
    end

    def replace_action(action_name, &block)
      action action_name do
        replace(&block)
      end
    end

    def override_action(action_name, params = {}, &block)
      action action_name, params.merge(override: true), &block
    end

    def require_resource_constant!(resource_name)
      if resource_name.to_s.singularize.camelize.safe_constantize.nil?
        fail UnknownResourceError
      end
    end
  end
end
