module Cathode
  class ActionRequest
    attr_reader :_body,
                :_status

    def initialize(action, context, &block)
      instance_eval(&block)
    end

  private

    def body(value = nil, &block)
      @_body = block_given? ? block.call : value
    end

    def status(value = nil, &block)
      @_status = block_given? ? block.call : value
    end
  end
end
