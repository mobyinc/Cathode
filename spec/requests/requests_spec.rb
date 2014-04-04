require 'spec_helper'

describe 'Requests' do
  describe 'GET #index' do
    subject { get 'api/products' }

    before { use_api %Q{resource :products, actions: [:index]} }

    let!(:products) { create_list(:product, 5) }

    it 'responds with all records' do
      subject
      expect(response.body).to eq(products.to_json)
    end
  end
end
