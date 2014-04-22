module Cathode
  class Request
    attr_reader :_body,
                :custom_logic,
                :_status,
                :resource,
                :model,
                :action,
                :context

    delegate :allowed?, to: :action
    delegate :params, to: :context

    class << self
      def create(context)
        klass = case context.params[:action].to_sym
                when :index
                  IndexRequest
                when :show
                  ShowRequest
                when :create
                  CreateRequest
                when :update
                  UpdateRequest
                when :destroy
                  DestroyRequest
                else
                  CustomRequest
                end
        klass.new(context)
      end
    end

    def initialize(context)
      @context = context

      version_number = context.request.headers['HTTP_ACCEPT_VERSION']

      if version_number.nil?
        @_status, @_body = :bad_request, 'A version number must be passed in the Accept-Version header'
        return self
      end

      version = Version.find(version_number)
      unless version.present?
        @_status, @_body = :bad_request, "Unknown API version: #{version_number}"
        return self
      end

      @resource = context.params[:controller].camelize.demodulize.downcase.to_sym

      binding.pry
      action_name = params[:action]
      if action_name == 'custom'
        action_name = context.request.path.split('/').last
      end

      unless version.action?(resource, action_name)
        @_status = :not_found
        return self
      end

      @action = version.resources.find(resource).actions.find(action_name.to_sym)
      @strong_params = @action.strong_params
      @_status = :ok

      if action.override_block
        context.instance_eval(&action.override_block)
      else
        action_block = action.action_block
        if action_block.nil? && respond_to?(:default_action_block)
          action_block = default_action_block
        end

        instance_eval(&action_block)
      end

      body if @_body.nil?
    end

  private

    def model
      resource.to_s.camelize.singularize.constantize
    end

    def body(value = Hash.new, &block)
      @_body = block_given? ? block.call : value
    end

    def status(value = nil, &block)
      @_status = block_given? ? block.call : value
    end
  end
end
