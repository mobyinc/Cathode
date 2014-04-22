Cathode::Engine.routes.draw do
  Cathode::Base.versions.each do |version|
    version.resources.each do |resource|
      resources resource.name, only: resource.default_actions.map(&:name) do
        resource.custom_actions.each do |action|
          match action.name => action.name, action: 'custom', via: action.http_method
        end
      end
    end
  end
  match '*path' => 'base#custom', via: [:get, :post, :put, :delete]
end
