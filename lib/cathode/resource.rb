module Cathode
  class Resource
    def initialize(resource_name, params = { actions: [] }, &block)
      require_resource_constant! resource_name

      Cathode.const_set "#{resource_name.to_s.camelize}Controller", Class.new(Cathode::BaseController)

      @actions = []
      actions_to_add = params[:actions] == [:all] ? [:index, :show, :create, :update, :destroy] : params[:actions]
      actions_to_add.each do |action_name|
        action action_name
      end
      self.instance_eval &block if block_given?
      actions = @actions

      Cathode::Engine.routes.draw do
        resources resource_name, only: actions.map(&:name)
      end
    end

  private

    def action(action, &block)
      @actions << Action.new(action, &block)
    end

    def require_resource_constant!(resource_name)
      if resource_name.to_s.singularize.camelize.safe_constantize.nil?
        raise UnknownResourceError
      end
    end
  end
end
