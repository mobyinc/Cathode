require 'spec_helper'

describe Cathode::ShowRequest do
  subject do
    Cathode::ShowRequest.new(context_stub(params: ActionController::Parameters.new(params.merge(controller: 'products', action: 'show'))))
  end
  before do
    use_api do
      resource :products, actions: [:show]
    end
  end

  let(:params) { { id: 3 } }
  let!(:products) { create_list(:product, 3) }

  it 'sets status as ok' do
    expect(subject._status).to eq(:ok)
  end

  it 'sets body as the resource' do
    expect(subject._body).to eq(products[2])
  end
end
