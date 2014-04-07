module Cathode
  class Action
    attr_reader :action_access_filter,
                :name

    def initialize(action, &block)
      @name = action
      self.instance_eval &block if block_given?
    end

  private

    def access_filter(&filter)
      @action_access_filter = filter
    end
  end
end
