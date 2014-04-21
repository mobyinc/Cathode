module SpecHelpers
  def initialize_resource(resource)
    Rails::Application.class_eval %Q(class #{resource.to_s.camelize} < ActiveRecord::Base; end)
  end

  def use_api(&block)
    Cathode::Base.define(&block)

    Rails.application.reload_routes!
  end

  def context_stub(options)
    headers = options[:headers] || { 'HTTP_ACCEPT_VERSION' => '1.0.0' }

    Struct.new(:request, :params).new(
      Struct.new(:headers, :path).new(headers, options[:path]),
      options[:params]
    )
  end
end
