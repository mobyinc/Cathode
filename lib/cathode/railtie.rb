require 'rack/cors'

module Cathode
  # Defines a Railtie to hook into the Rails initialization process. Autoloads
  # API code from the `app/api` directory and adds `Rack::Cors` to the
  # application's middleware stack.
  class Railtie < Rails::Railtie
    initializer 'cathode.add_api_to_autoload_paths' do |app|
      Dir[File.join(Rails.root, 'app', 'api', '**', '*.rb')].each { |f| require f }
    end

    initializer 'cathode.enable_cors' do |app|
      app.config.middleware.use Rack::Cors do
        allow do
          origins '*'
          resource '*', headers: :any, methods: [:get, :post, :put, :delete, :options]
        end
      end
    end
  end
end
