module Cathode
  class Request
    attr_reader :body,
                :status

    def initialize(http_request, params)
      version = http_request.headers['HTTP_ACCEPT_VERSION']

      resource = params['controller'].camelize.demodulize.downcase.to_sym
      response = Version.perform_request_with_version(version, resource, params)

      @status, @body = response[:status], response[:body]
    end
  end
end
