require 'spec_helper'

describe Cathode::CreateRequest do
  subject do
    Cathode::CreateRequest.new(context_stub(params: ActionController::Parameters.new(params.merge(controller: 'products', action: 'create'))))
  end
  before do
    use_api do
      resource :products, actions: [:create] do
        attributes do
          params.require(:product).permit(:title)
        end
      end
    end
  end

  context 'with valid attributes' do
    let(:params) { { product: { title: 'cool product' } } }

    it 'sets status as ok' do
      expect(subject._status).to eq(:ok)
    end

    it 'sets body as the new record' do
      expect(subject._body.title).to eq('cool product')
    end
  end

  context 'with invalid attributes' do
    let(:params) { { title: 'cool product' } }

    it 'sets status as bad request' do
      expect(subject._status).to eq(:bad_request)
    end

    it 'sets body as error message' do
      expect(subject._body).to eq('param is missing or the value is empty: product')
    end
  end
end
