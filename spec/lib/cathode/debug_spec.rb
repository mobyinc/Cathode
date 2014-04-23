require 'spec_helper'

describe Cathode::Debug do
  before do
    use_api do
      resources :products, actions: [:index]
      version 2 do
        resources :sales, actions: :all do
          attributes do
            params.require(:sale)
          end
        end
      end
    end
  end

  describe '.info' do
    subject { Cathode::Debug.info }

    it 'returns the info' do
      puts subject
#      expect(subject).to eq("Version 1.0.0\n\tproducts")
    end
  end
end
