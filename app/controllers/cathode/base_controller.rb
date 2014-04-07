class Cathode::BaseController < ActionController::Base
  def index
    render json: resources.load
  end

  def show
    render json: resource
  end

  def create
    render json: model.create(resource_params)
  end

  def destroy
    resource.destroy
    head :ok
  end

  def allows_pagination?
    @allows_pagination
  end

private

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
end
