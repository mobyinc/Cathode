module Cathode
  class Resource
    include ActionDsl
    include ResourceDsl

    attr_reader :name,
                :controller_prefix,
                :model

    def initialize(resource_name, params = nil, context = nil, &block)
      require_resource_constant! resource_name

      params ||= { actions: [] }

      @name = resource_name

      camelized_resource = resource_name.to_s.camelize
      @controller_prefix = if context.present? && context.respond_to?(:controller_prefix)
                             "#{context.controller_prefix}#{camelized_resource}"
                           else
                             camelized_resource
                           end
      controller_name = "#{@controller_prefix}Controller"
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
      constant = resource_name.to_s.singularize.camelize
      @model = constant.safe_constantize
      if @model.nil?
        fail UnknownResourceError, "Could not find constant `#{constant}' for resource `#{resource_name}'"
      end
    end
  end
end
