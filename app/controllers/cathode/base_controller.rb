class Cathode::BaseController < ActionController::Base
  def index
    make_request request
  end

  def show
    make_request request
  end

  def create
  end

  def update
  end

  def destroy
    make_request request
  end

private

  def make_request(http_request)
    request = Cathode::Request.new(http_request, params)
    render json: request.body, status: request.status
  end

  def resource_params
    params[controller_name.singularize]
  end
end
