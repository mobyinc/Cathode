class Cathode::BaseController < ActionController::Base
  def index
    render json: resource.all
  end

private

  def resource
    @resource ||= controller_name.classify.constantize
  end
end
