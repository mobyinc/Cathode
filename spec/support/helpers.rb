module SpecHelpers
  def initialize_resource(resource)
    Rails::Application.class_eval %Q{class #{resource.to_s.camelize} < ActiveRecord::Base; end}
  end

  def use_api(api)
    Class.new(Cathode::Base).class_eval api
  end
end
