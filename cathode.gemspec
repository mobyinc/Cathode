$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cathode/_version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cathode"
  s.version     = Cathode::VERSION
  s.authors     = ["Moby, Inc."]
  s.email       = ["contact@builtbymoby.com"]
  s.homepage    = "https://github.com/mobyinc/Cathode"
  s.summary     = "API boilerplate for RESTful applications"
  s.description = "Provides API boilerplate (routes + controllers) for REST actions, with robust support for versioning"

  s.files = Dir["{app,config,db,lib}/**/*", "LICENSE", "Rakefile", "README.md"]
  s.test_files = Dir["spec/**/*"]

  s.add_dependency "rails", "~> 4.0.4"
  s.add_dependency 'semantic', '~> 1.3.0'

  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'capybara'
  s.add_development_dependency 'factory_girl_rails'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'pry-debugger'
end
