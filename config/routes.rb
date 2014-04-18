Cathode::Engine.routes.draw do
  Cathode::Base.versions.each do |version_number, version|
    version.resources.each do |name, resource|
      resources name, only: resource.default_actions.keys do
        resource.custom_actions.each do |action_name, action|
          match action_name => action_name, action: 'custom', via: action.http_method
        end
      end
    end
  end
  match '*path' => 'base#custom', via: [:get, :post, :put, :delete]
end
