require 'spec_helper'

describe Cathode::Debug do
  before do
    use_api do
      resource :products, actions: [:index]
    end
  end

  describe '.info' do
    subject { Cathode::Debug.info }

    it 'returns the info' do
      expect(subject).to eq("Version 1.0.0\n\tproducts")
    end
  end
end
