puts 'here'
class DummyApi < Cathode::Base
  resource :products, actions: [:index]
end
