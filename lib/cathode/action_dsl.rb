module Cathode
  # Holds the domain-specific language (DSL) for describing actions.
  module ActionDsl
    # Lists the actions that are default (i.e., `index`, `show`, `create`,
    #   `update`, and `destroy`)
    # @return [Array] The default actions
    def default_actions
      actions.select { |action| DEFAULT_ACTIONS.include? action.name }
    end

    # Lists the actions that are not default
    # @return [Array] The custom actions
    def custom_actions
      actions - default_actions
    end

    # Lists all the actions; initializes an empty `ObjectCollection` if there
    # aren't any yet
    # @return [Array] The actions
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
