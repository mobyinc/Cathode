module Cathode
  class BaseController < ActionController::Base
    def index
      make_request
    end

    def show
      make_request
    end

    def create
      make_request
    end

    def update
      make_request
    end

    def destroy
      make_request
    end

    def custom
      make_request
    end

  private

    def make_request
      request = Cathode::Request.create self

      render json: request._body, status: request._status unless performed?
    end

    def resource_params
      params[controller_name.singularize]
    end
  end
end
