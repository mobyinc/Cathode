$:.push File.expand_path("../lib", __FILE__)

require 'cathode/_version'

Gem::Specification.new do |s|
  s.name        = 'cathode'
  s.version     = Cathode::VERSION
  s.authors     = ['Moby, Inc.']
  s.email       = ['contact@builtbymoby.com']
  s.homepage    = 'https://github.com/mobyinc/cathode'
  s.summary     = 'API boilerplate for Rails applications'
  s.description = 'Provides dynamic (runtime, no generated files) boilerplate (routes + controllers) and default CRUD actions for resourceful Rails apps'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['spec/**/*']

  s.required_ruby_version = '>= 1.9.3'

  s.add_dependency 'rack-cors', '~> 0.2.9'
  s.add_dependency 'rails', '~> 4.0.0'
  s.add_dependency 'ruby_deep_clone', '~> 0.6.0'
  s.add_dependency 'semantic', '~> 1.3.0'

  s.add_development_dependency 'simplecov', '~> 0.7.1'
  s.add_development_dependency 'coveralls', '~> 0.7.0'
  s.add_development_dependency 'factory_girl_rails', '~> 4.4.1'
  s.add_development_dependency 'pry-debugger', '~> 0.2.2'
  s.add_development_dependency 'rspec-rails', '~> 2.14.2'
  s.add_development_dependency 'rubocop', '~> 0.20.1'
  s.add_development_dependency 'timecop', '~> 0.7.1'
  s.add_development_dependency 'yard', '~> 0.8.7'
end
