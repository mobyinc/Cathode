require 'spec_helper'

describe Cathode::CustomRequest do
  subject do
    Cathode::CustomRequest.new(context_stub(
      params: ActionController::Parameters.new(params.merge(controller: 'products', action: 'custom')),
      path: 'products/custom'
    ))
  end

  before do
    use_api do
      resource :products do
        get :custom do
          body Product.last
        end
      end
    end
  end

  let!(:products) { create_list(:product, 3) }
  let(:params) { {} }

  it 'sets status as ok' do
    expect(subject._status).to eq(:ok)
  end

  it 'sets body' do
    expect(subject._body).to eq(Product.last)
  end
end
