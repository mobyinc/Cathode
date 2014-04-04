module Cathode
  class Resource
    def initialize(resource_name, params)
      require_resource_constant! resource_name

      Cathode.const_set "#{resource_name.to_s.camelize}Controller", Class.new(Cathode::BaseController)

      Cathode::Engine.routes.draw do
        resources resource_name
      end
    end

  private

    def require_resource_constant!(resource_name)
      if resource_name.to_s.singularize.camelize.safe_constantize.nil?
        raise UnknownResourceError
      end
    end
  end
end
