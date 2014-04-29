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
        resources :products, actions: [:index]
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
          resources :products, actions: :all do
            attributes do
              params.require(:product).permit(:title, :cost)
            end
          end
          resources :sales, actions: [:index, :show]
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
        resources :products, actions: [:index, :show]
        version '1.0.1' do
          resources :sales, actions: [:index, :show]
        end
        version 1.1 do
          remove_resources :sales
          resources :products, actions: [:index]
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
        resources :products do
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
        resources :products do
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

  context 'with nested resources' do
    before do
      use_api do
        resources :products do
          resources :sales, actions: [:index]
        end
        resources :sales do
          resource :payment, actions: [:show, :create, :update, :destroy] do
            attributes do
              params.require(:payment).permit(:amount)
            end
          end
        end
        resources :payments do
          resource :sale, actions: [:show]
        end
      end
    end
    let!(:product) { create(:product) }
    let!(:sale) { create(:sale, product: product) }

    context 'with has_many association' do
      it 'uses the associations to get the records' do
        make_request :get, 'api/products/1/sales'
        expect(response.status).to eq(200)
        expect(response.body).to eq(Sale.all.to_json)
      end
    end

    context 'with has_one association' do
      context ':show' do
        let!(:payment) { create(:payment, sale: sale) }

        it 'gets the association record' do
          make_request :get, 'api/sales/1/payment'
          expect(response.status).to eq(200)
          expect(response.body).to eq(payment.to_json)
        end
      end

      context ':create' do
        subject { make_request :post, 'api/sales/1/payment', { payment: { amount: 500 } } }

        it 'adds a new record associated with the parent' do
          expect { subject }.to change(Payment, :count).by(1)
          expect(Payment.last.sale).to eq(sale)
          expect(response.status).to eq(200)
          expect(response.body).to eq(Payment.last.to_json)
        end
      end

      context ':update' do
        let!(:payment) { create(:payment, amount: 200, sale: sale) }
        subject { make_request :put, 'api/sales/1/payment', { payment: { amount: 500 } } }

        it 'updates the associated record' do
          expect { subject }.to_not change(Payment, :count).by(1)
          expect(response.status).to eq(200)
          expect(JSON.parse(response.body)['amount']).to eq(500)
        end
      end

      context ':destroy' do
        let!(:payment) { create(:payment, amount: 200, sale: sale) }
        subject { make_request :delete, 'api/sales/1/payment' }

        it 'deletes the associated record' do
          expect { subject }.to change(Payment, :count).by(-1)
          expect(response.status).to eq(200)
          expect(sale.payment).to be_nil
        end
      end
    end

    context 'with belongs_to association' do
      context ':show' do
        let!(:payment) { create(:payment, sale: sale) }

        it 'gets the association record' do
          make_request :get, 'api/payments/1/sale'
          expect(response.status).to eq(200)
          expect(response.body).to eq(sale.to_json)
        end
      end
    end
  end

  context 'with a custom action' do
    before do
      use_api do
        resources :products do
          override_action :custom_override, method: :get do
            render json: Product.last
          end
          get :custom_replace do
            attributes do
              params.require(:flag)
            end
            body Product.all.reverse
          end
        end
      end
    end

    let!(:products) { create_list(:product, 3) }

    context 'with replace (default)' do
      subject { make_request(:get, 'api/products/custom_replace', { flag: true }, '1.0') }

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

    context 'with attributes block' do
      subject { make_request(:get, 'api/products/custom_replace', nil, '1.0') }

      it 'sets the status' do
        subject
        expect(response.status).to eq(400)
      end

      it 'sets the body' do
        subject
        expect(response.body).to eq('param is missing or the value is empty: flag')
      end
    end
  end

  describe 'token auth' do
    subject { get 'api/products', nil, headers }
    let(:headers) { { 'HTTP_ACCEPT_VERSION' => '1.0.0' } }
    before do
      api = proc do |required|
        proc do
          require_tokens if required
          resources :products, actions: [:index]
        end
      end
      use_api(&api.call(required))
    end

    context 'when tokens are required' do
      let(:required) { true }

      context 'with a valid token' do
        let(:token) { create(:token) }
        before { headers['Authorization'] = "Token token=#{token.token}" }

        it 'responds with ok' do
          expect(subject).to eq(200)
        end
      end

      context 'with an invalid token' do
        before { headers['Authorization'] = 'Token token=invalid' }

        it 'responds with unauthorized' do
          expect(subject).to eq(401)
        end
      end

      context 'with no token' do
        it 'responds with unauthorized' do
          expect(subject).to eq(401)
        end
      end
    end

    context 'when tokens are not required' do
      let(:required) { false }

      it 'responds with ok' do
        expect(subject).to eq(200)
      end
    end
  end
end
