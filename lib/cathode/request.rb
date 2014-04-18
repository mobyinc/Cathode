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
    delegate :render, to: :context

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
      unless version.action?(resource, context.params[:action])
        @_status = :not_found
        return self
      end

      @action = version.resources[resource].actions[context.params[:action].to_sym]
      @strong_params = @action.strong_params
      @_status = :ok

      action_block = action.action_block || default_action_block
      instance_eval(&action_block)

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

  class IndexRequest < Request
    def default_action_block
      proc do
        all_records = model.all

        if allowed?(:paging) && params[:page]
          page = params[:page]
          per_page = params[:per_page] || 10
          lower_bound = (per_page - 1) * page
          upper_bound = lower_bound + per_page - 1

          body all_records[lower_bound..upper_bound]
        else
          body all_records
        end
      end
    end
  end

  class ShowRequest < Request
    def default_action_block
      proc do
        body model.find params[:id]
      end
    end
  end

  class CreateRequest < Request
    def default_action_block
      proc do
        begin
          body model.create(instance_eval(&@strong_params))
        rescue ActionController::ParameterMissing => error
          body error.message
          status :bad_request
        end
      end
    end
  end

  class UpdateRequest < Request
    def default_action_block
      proc do
        begin
          record = model.find(params[:id])
          record.update(instance_eval(&@strong_params))
          body record.reload
        rescue ActionController::ParameterMissing => error
          body error.message
          status :bad_request
        end
      end
    end
  end

  class DestroyRequest < Request
    def default_action_block
      proc do
        model.find(params[:id]).destroy
      end
    end
  end

  class CustomRequest < Request; end
end
