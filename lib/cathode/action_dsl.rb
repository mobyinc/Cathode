module Cathode
  module ActionDsl
    def default_actions
      actions.select { |action| DEFAULT_ACTIONS.include? action.name }
    end

    def custom_actions
      actions - default_actions
    end

    def actions
      @actions ||= ObjectCollection.new
    end

  protected

    def action(action, params = {}, &block)
      actions << Action.create(action, self, params, &block)
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

    def attributes(&block)
      @strong_params = block
    end
  end
end
