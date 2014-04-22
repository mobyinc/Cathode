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

      @actions = ObjectCollection.new
      actions_to_add = params[:actions] == :all ? DEFAULT_ACTIONS : params[:actions]
      actions_to_add.each do |action_name|
        action action_name
      end
      instance_eval(&block) if block_given?

      @actions.each do |action|
        action.after_resource_initialized if action.respond_to? :after_resource_initialized
      end
    end

    def default_actions
      actions.select { |action| DEFAULT_ACTIONS.include? action.name }
    end

    def custom_actions
      actions - default_actions
    end

  private

    def action(action, params = {}, &block)
      @actions << Action.create(action, @name, params, &block)
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
      create_action = @actions.find(:create)
      update_action = @actions.find(:update)

      unless create_action || update_action
        fail UnknownActionError, 'An attributes block was specified without a :create or :update action'
      end

      create_action.strong_params = block if create_action.present?
      update_action.strong_params = block if update_action.present?
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
