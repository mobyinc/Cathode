class Cathode::BaseController < ActionController::Base
  before_action :process_access_filter

  def index
    render json: resources.load
  end

  def create
    render json: model.create(resource_params)
  end

  def destroy
    resource.destroy
    head :ok
  end

  def show
    make_request
  end

private

  def make_request
    request = Cathode::Request.new(params)
    render json: request.body, status: request.status
  end

  def resources
    model.all
  end

  def resource
    model.find params[:id]
  end

  def resource_params
    params[controller_name.singularize]
  end

  def model
    controller_name.classify.constantize
  end

  def process_access_filter

  end
end
