require 'rack/cors'

module Cathode
  class Railtie < Rails::Railtie
    # TODO: Don't hardcode api/ dir here, find a better way
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
