module Cathode
  # Defines a basic controller for all Cathode controllers to inherit from.
  # Intercepts all Rails requests and sends them off to {Request} with the
  # context to to be processed.
  class BaseController < ActionController::Base
    %w(index show create update destroy custom).each do |method|
      define_method method do
        make_request
      end
    end

  private

    def make_request
      if Cathode::Base.tokens_required
        authenticate_or_request_with_http_token do |token|
          Token.find_by token: token
        end
      end

      request = Cathode::Request.create self

      render json: request._body, status: request._status unless performed?
    end

    def resource_params
      params[controller_name.singularize]
    end
  end
end
