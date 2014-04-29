ENV['RAILS_ENV'] ||= 'test'

require 'coveralls'
Coveralls.wear!

require File.expand_path('../dummy/config/environment.rb',  __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'factory_girl_rails'
require 'timecop'
require 'pry'

Rails.backtrace_cleaner.remove_silencers!

# Load support files

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  config.mock_with :rspec
  config.use_transactional_fixtures = true
  config.infer_base_class_for_anonymous_controllers = false
  config.order = 'random'
  config.include FactoryGirl::Syntax::Methods
  config.include SpecHelpers

  config.after(:each) do
    Cathode::BaseController.subclasses.each do |controller|
      name = controller.name.try(:demodulize)
      if name.present? && Cathode.const_defined?(name)
        Cathode.send(:remove_const, name.to_sym)
      end
    end
    Cathode::Base.send :reset!
  end
end
