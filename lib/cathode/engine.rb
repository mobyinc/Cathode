module Cathode
  class Engine < ::Rails::Engine
    isolate_namespace Cathode

    config.before_eager_load { |app| app.reload_routes! }
  end
end
