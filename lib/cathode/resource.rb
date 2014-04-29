module Cathode
  # A `Resource` is paired with a Rails model and describes the actions that the
  # resource responds to.
  class Resource
    include ActionDsl
    include ResourceDsl

    attr_reader :controller_prefix,
                :model,
                :name,
                :parent,
                :singular,
                :strong_params

    # Creates a new resource.
    # @param resource_name [Symbol] The resource's name
    # @param params [Hash] An optional params hash, e.g. `{ actions: :all }`
    # @param context [Resource] An optional parent resource
    # @param block The resource's actions and properties, defined with the
    #   {ActionDsl} and {ResourceDsl}
    def initialize(resource_name, params = nil, context = nil, &block)
      require_resource_constant! resource_name

      params ||= {}
      params[:actions] ||= []

      @name = resource_name

      camelized_resource = resource_name.to_s.camelize

      @controller_prefix = if context.present? && context.is_a?(Resource)
        @parent = context
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
      actions_to_add.each { |action_name| action action_name }

      @singular = params[:singular]

      instance_eval(&block) if block_given?

      @actions.each do |action|
        action.after_resource_initialized if action.respond_to? :after_resource_initialized
      end

      if @strong_params.present? && actions.find(:create).nil? && actions.find(:update).nil?
        raise UnknownActionError,
          'An attributes block was specified without a :create or :update action'
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
