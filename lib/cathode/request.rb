module Cathode
  class Request
    attr_reader :body,
                :custom_logic,
                :status

    def initialize(context)
      version_number = context.request.headers['HTTP_ACCEPT_VERSION']

      if version_number.nil?
        @status, @body = :bad_request, 'A version number must be passed in the Accept-Version header'
        return self
      end

      version = Version.find(version_number)
      unless version.present?
        @status, @body = :bad_request, "Unknown API version: #{version_number}"
        return self
      end

      resource = context.params[:controller].camelize.demodulize.downcase.to_sym
      unless version.action?(resource, context.params[:action])
        @status = :not_found
        return self
      end

      response = version.perform_request resource, context

      if response[:custom_logic]
        @custom_logic = response[:custom_logic]
      else
        @status, @body = response[:status], response[:body]
      end
    end
  end
end
