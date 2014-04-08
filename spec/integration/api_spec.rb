require 'spec_helper'

def make_request(method, path, params = nil, version = '1.0.0')
  send(method, path, params, { 'Accept-Version' => version })
end

def request_spec(method, path, params = nil, &block)
  context 'without version header' do
    subject { send(method, path, params) }

    it 'responds with bad request' do
      expect(subject).to eq(400)
      expect(response.body).to eq('Accept-Version header was not passed')
    end
  end

  context 'with invalid version header' do
    subject { make_request method, path, params, '2.0.0' }

    it 'responds with bad request' do
      expect(subject).to eq(400)
      expect(response.body).to eq('Unknown API version: 2.0.0')
    end
  end

  context 'with valid version header' do
    subject { make_request method, path, params, '1.5.0' }

    instance_eval &block
  end
end

describe 'API' do
  context 'with no explicit version' do
    before(:all) do
      use_api do
        resource :products, actions: [:index]
      end
    end

    let!(:products) { create_list(:product, 5) }

    it 'makes a request' do
      make_request :get, 'api/products'
      expect(response.body).to eq(products.to_json)
    end
  end

  context 'with explicit version' do
    before(:all) do
      use_api do
        version 1.5 do
          resource :products, actions: [:all]
        end
      end
    end

    let!(:products) { create_list(:product, 5) }

    describe 'index' do
      request_spec :get, 'api/products', nil do
        it 'responds with all records' do
          subject
          expect(response.body).to eq(products.to_json)
        end
      end
    end

    describe 'show' do
      request_spec :get, 'api/products/1' do
        it 'responds with all records' do
          subject
          expect(response.body).to eq(products.first.to_json)
        end
      end
    end

    describe 'create' do
      request_spec :post, 'api/products', product: { title: 'hello', cost: 1900 } do
        it 'responds with the new record' do
          subject
          expect(response.body).to eq(Product.new(title: 'hello', cost: 1900).to_json)
        end
      end
    end

    describe 'update' do
      request_spec :put, 'api/products/1', product: { title: 'goodbye' } do
        it 'responds with the new record' do
          subject
          expect(JSON.parse(response.body)['title']).to eq('goodbye')
        end
      end
    end

    describe 'destroy' do
      request_spec :delete, 'api/products/5' do
        it 'responds with success' do
          expect(subject).to eq(200)
        end
      end
    end
  end
end
