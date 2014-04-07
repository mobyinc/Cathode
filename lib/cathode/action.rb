module Cathode
  class Action
    attr_reader :action_access_filter,
                :name,
                :resource


    def self.create(action, resource, &block)
      klass = case action
              when :index
                IndexAction
              when :show
                ShowAction
              when :create
                CreateAction
              when :update
                UpdateAction
              when :destroy
                DestroyAction
              end
      klass.new(action, resource, &block)
    end

    def initialize(action, resource, &block)
      @name, @resource = action, resource

      self.instance_eval &block if block_given?
    end

    def perform(params)
      if action_access_filter && !action_access_filter.call
        return { status: :unauthorized }
      end

      body = perform_action params

      return { body: body, status: :ok }
    end

  private

    def model
      resource.to_s.camelize.singularize.constantize
    end

    def access_filter(&filter)
      @action_access_filter = filter
    end
  end

  class IndexAction < Action
    def perform_action(params)
      model.all
    end
  end

  class ShowAction < Action
    def perform_action(params)
      model.find params[:id]
    end
  end

  class CreateAction < Action; end

  class UpdateAction < Action; end

  class DestroyAction < Action; end
end
