def attach_resources(resources)
  resources.each do |resource|
    resources resource.name, controller: resource.controller_prefix.underscore, only: resource.default_actions.map(&:name) do
      resource.custom_actions.each do |action|
        match action.name => action.name, action: 'custom', via: action.http_method
      end
      attach_resources(resource.resources)
    end
  end
end

Cathode::Engine.routes.draw do
  Cathode::Base.versions.each do |version|
    attach_resources(version.resources)
  end
  match '*path' => 'base#custom', via: [:get, :post, :put, :delete]
end
