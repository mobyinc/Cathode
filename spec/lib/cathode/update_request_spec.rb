require 'spec_helper'

describe Cathode::UpdateRequest do
  subject do
    Cathode::UpdateRequest.new(context_stub(params: ActionController::Parameters.new(params.merge(controller: 'products', action: 'update'))))
  end
  before do
    use_api do
      resources :products, actions: [:update] do
        attributes do
          params.require(:product).permit(:title)
        end
      end
    end
  end
  let!(:product) { create(:product, title: 'cool product') }

  context 'with valid attributes' do
    let(:params) { { id: product.id, product: { title: 'cooler product' } } }

    it 'sets status as ok' do
      expect(subject._status).to eq(:ok)
    end

    it 'sets body as the updated record' do
      expect(subject._body.title).to eq('cooler product')
    end
  end

  context 'with invalid attributes' do
    let(:params) { { id: product.id, title: 'cooler product' } }

    it 'sets status as bad request' do
      expect(subject._status).to eq(:bad_request)
    end

    it 'sets body as error message' do
      expect(subject._body).to eq('param is missing or the value is empty: product')
    end
  end
end
