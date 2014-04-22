module Cathode
  class Resource
    include ActionDsl

    attr_reader :name

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

  private

    def require_resource_constant!(resource_name)
      if resource_name.to_s.singularize.camelize.safe_constantize.nil?
        fail UnknownResourceError
      end
    end
  end
end
