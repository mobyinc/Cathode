require 'spec_helper'

describe Cathode::IndexRequest do
  subject do
    Cathode::IndexRequest.new(context_stub(params: ActionController::Parameters.new(params.merge(controller: resource, action: 'index'))))
  end
  let!(:products) { create_list(:product, 5) }
  before do
    use_api do
      resource :products do
        action :index do
          allows :paging
        end
      end

      resource :sales, actions: [:index]
    end
  end

  describe 'with no params' do
    let(:params) { {} }
    let(:resource) { 'products' }
    let(:block) { nil }

    it 'sets status as ok' do
      expect(subject._status).to eq(:ok)
    end

    it 'sets body as all resource records' do
      expect(subject._body).to eq(Product.all)
    end
  end

  describe 'with paging' do
    let(:params) { { page: 2, per_page: 2 } }

    context 'when allowed' do
      let(:resource) { 'products' }

      it 'sets status as ok' do
        expect(subject._status).to eq(:ok)
      end

      it 'sets body as the paged results' do
        expect(subject._body).to eq(products[2..3])
      end
    end

    context 'when not allowed' do
      let(:resource) { 'sales' }
      let!(:sales) { create_list(:sale, 5) }

      it 'sets status as ok' do
        expect(subject._status).to eq(:ok)
      end

      it 'sets body as all records' do
        expect(subject._body).to eq(sales)
      end
    end
  end
end
