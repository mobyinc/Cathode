Cathode::Engine.routes.draw do
  Cathode::Base.versions.each do |version_number, version|
    version.resources.each do |name, resource|
      resources name, only: resource.actions.keys
    end
  end
  match '*path' => 'base#index', via: [:get, :post]
end
