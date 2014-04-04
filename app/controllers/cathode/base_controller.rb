class Cathode::BaseController < ActionController::Base
  def index
    binding.pry
  end

private

  def resource
    @resource ||= controller_name.classify.constantize
  end
end
