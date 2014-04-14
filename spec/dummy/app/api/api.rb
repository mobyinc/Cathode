class API < Cathode::Base
  resource :products, actions: [:all]
  version '1.0.1' do
    resource :sales, actions: [:index, :show]
  end
  version 1.1 do
    #remove_resource :products
  end
end
