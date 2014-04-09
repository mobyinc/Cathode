module Cathode
  class Railtie < Rails::Railtie
    # TODO: Don't hardcode the `api` directory; be more flexible
    initializer 'cathode.require_apis' do |app|
      require "#{app.config.root}/app/api/api"
    end
  end
end
