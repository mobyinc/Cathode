require 'spec_helper'

def make_request(method, path, params = nil, version = '1.0.0')
  send(method, path, params,  'Accept-Version' => version)
end

def request_spec(method, path, params = nil, &block)
  context 'without version header' do
    subject { send(method, path, params) }

    it 'responds with bad request' do
      expect(subject).to eq(400)
      expect(response.body).to eq('A version number must be passed in the Accept-Version header')
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

    instance_eval(&block)
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
    before do
      use_api do
        version 1.5 do
          resource :products, actions: :all do
            attributes do
              params.require(:product).permit(:title, :cost)
            end
          end
          resource :sales, actions: [:index, :show]
        end
      end
    end

    let!(:products) { create_list(:product, 5) }

    describe 'resources with all actions' do
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
            parsed_response = JSON.parse(response.body)
            expect(parsed_response['title']).to eq('hello')
            expect(parsed_response['cost']).to eq(1900)
          end
        end
      end

      describe 'update' do
        request_spec :put, 'api/products/1', product: { title: 'goodbye' } do
          it 'responds with the updated record' do
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

    describe 'resources with only some actions' do
      it 'does not add the non-specified actions' do
        pending
      end
    end

    describe 'to a nonexistent endpoint' do
      subject { make_request :get, 'api/boxes', nil, '1.5.0' }

      it 'responds with 404' do
        subject
        expect(response.status).to eq(404)
      end
    end
  end

  context 'with cascading versions' do
    before(:each) do
      use_api do
        resource :products, actions: [:index, :show]
        version '1.0.1' do
          resource :sales, actions: [:index, :show]
        end
        version 1.1 do
          remove_resource :sales
          resource :products, actions: [:index]
        end
      end
    end

    let!(:product) { create :product }

    it 'inherits from previous versions' do
      make_request :get, 'api/products', nil, '1.0'
      expect(response.status).to eq(200)

      make_request :get, 'api/products/1', nil, '1.0'
      expect(response.status).to eq(200)

      make_request :get, 'api/sales', nil, '1.0'
      expect(response.status).to eq(404)

      make_request :get, 'api/sales', nil, '1.0.1'
      expect(response.status).to eq(200)

      make_request :get, 'api/sales', nil, '1.1.0'
      expect(response.status).to eq(404)

      make_request :get, 'api/products/1', nil, '1.1.0'
      expect(response.status).to eq(200)

      make_request :get, 'api/products', nil, '1.1.0'
      expect(response.status).to eq(200)
    end
  end

  context 'with action replacing' do
    before do
      use_api do
        resource :products do
          action :show do
            replace do
              body Product.last
            end
          end
          replace_action :index do
            body Product.all.reverse
          end
        end
      end
    end

    let!(:products) { create_list(:product, 3) }

    describe 'with replace defined inside action' do
      subject { make_request(:get, 'api/products/1', nil, '1.0') }

      it 'uses the replace logic instead of the default behavior' do
        subject
        expect(response.body).to eq(Product.last.to_json)
      end
    end

    describe 'with replace defined as the action' do
      subject { make_request(:get, 'api/products', nil, '1.0') }

      it 'uses the replace logic instead of the default behavior' do
        subject
        expect(JSON.parse(response.body).map { |p| p['id'] }).to eq(Product.all.reverse.map(&:id))
      end
    end
  end

  context 'with action overriding' do
    before do
      use_api do
        resource :products do
          action :show do
            override do
              render json: Product.last
            end
          end
          override_action :index do
            render json: Product.all.reverse
          end
        end
      end
    end

    let!(:products) { create_list(:product, 3) }

    describe 'with override defined inside action' do
      subject { make_request(:get, 'api/products/1', nil, '1.0') }

      it 'uses the custom logic instead of the default behavior' do
        subject
        expect(response.body).to eq(Product.last.to_json)
      end
    end

    describe 'with override defined as the action' do
      subject { make_request(:get, 'api/products', nil, '1.0') }

      it 'uses the custom logic instead of the default behavior' do
        subject
        expect(JSON.parse(response.body).map { |p| p['id'] }).to eq(Product.all.reverse.map(&:id))
      end
    end
  end

  context 'with a custom action' do
    before do
      use_api do
        resource :products do
          override_action :custom_override, method: :get do
            render json: Product.last
          end
          get :custom_replace do
            body Product.all.reverse
          end
        end
      end
    end

    let!(:products) { create_list(:product, 3) }

    context 'with replace (default)' do
      subject { make_request(:get, 'api/products/custom_replace', nil, '1.0') }

      it 'sets the status' do
        subject
        expect(response.status).to eq(200)
      end

      it 'sets the body with the replace logic' do
        subject
        expect(JSON.parse(response.body).map { |p| p['id'] }).to eq(Product.all.reverse.map(&:id))
      end
    end

    context 'with override' do
      subject { make_request(:get, 'api/products/custom_override', nil, '1.0') }

      it 'sets the status' do
        subject
        expect(response.status).to eq(200)
      end

      it 'uses the override logic' do
        subject
        expect(response.body).to eq(Product.last.to_json)
      end
    end
  end
end
