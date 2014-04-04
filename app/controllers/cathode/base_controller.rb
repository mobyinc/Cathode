class Cathode::BaseController < ActionController::Base
  def index
    render json: resources.load
  end

  def show
    render json: resource
  end

private

  def resources
    model.all
  end

  def resource
    model.find params[:id]
  end

  def model
    controller_name.classify.constantize
  end
end
