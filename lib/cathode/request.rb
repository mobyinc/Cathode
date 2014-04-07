module Cathode
  class Request
    attr_reader :body,
                :status

    def initialize(params)
      resource = params['controller'].camelize.demodulize.downcase.to_sym
      response = Cathode::Base.resources[resource].actions[params[:action].to_sym].perform(params)

      @status, @body = response[:status], response[:body]
    end
  end
end
