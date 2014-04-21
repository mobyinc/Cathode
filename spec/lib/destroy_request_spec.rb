require 'spec_helper'

describe Cathode::DestroyRequest do
  subject do
    Cathode::DestroyRequest.new(context_stub(params: ActionController::Parameters.new(params.merge(controller: 'products', action: 'destroy'))))
  end
  before do
    use_api do
      resource :products, actions: [:destroy]
    end
  end

  let(:action) { 'destroy' }
  let(:params) { { id: product.id } }
  let!(:product) { create(:product) }

  it 'sets status as ok' do
    expect(subject._status).to eq(:ok)
  end

  it 'sets body as empty' do
    expect(subject._body).to be_empty
  end

  it 'removes the record' do
    expect { subject }.to change { Product.count }.by(-1)
  end
end
