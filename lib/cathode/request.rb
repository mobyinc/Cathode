module Cathode
  class Request
    attr_reader :body,
                :custom_logic,
                :status

    def initialize(context)
      version = context.request.headers['HTTP_ACCEPT_VERSION']

      if version.nil?
        response = { status: 400, body: 'Accept-Version header was not passed' }
      else
        resource = context.params[:controller].camelize.demodulize.downcase.to_sym
        response = Version.perform_request_with_version(version, resource, context)
      end

      if response[:custom_logic]
        @custom_logic = response[:custom_logic]
      else
        @status, @body = response[:status], response[:body]
      end
    end
  end
end
