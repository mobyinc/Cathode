module SpecHelpers
  def initialize_resource(resource)
    Rails::Application.class_eval %Q{class #{resource.to_s.camelize} < ActiveRecord::Base; end}
  end

  def use_api(&block)
    Cathode::Base.define &block

    Rails.application.reload_routes!
  end

  def context_stub(params)
    context = Cathode::BaseController.new
    context.params = params
    context
  end
end
