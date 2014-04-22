module Cathode
  module ActionDsl
    def actions
      @actions ||= ObjectCollection.new
    end

    def action(action, params = {}, &block)
      actions << Action.create(action, @name, params, &block)
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

    def replace_action(action_name, &block)
      action action_name do
        replace(&block)
      end
    end

    def override_action(action_name, params = {}, &block)
      action action_name, params.merge(override: true), &block
    end

    def default_actions
      actions.select { |action| DEFAULT_ACTIONS.include? action.name }
    end

    def custom_actions
      actions - default_actions
    end

    def attributes(&block)
      create_action = actions.find :create
      update_action = actions.find :update

      unless create_action || update_action
        fail UnknownActionError, 'An attributes block was specified without a :create or :update action'
      end

      create_action.strong_params = block if create_action.present?
      update_action.strong_params = block if update_action.present?
    end
  end
end
