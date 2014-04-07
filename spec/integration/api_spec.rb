require 'spec_helper'

describe 'API' do
  context 'with the default API (all actions)' do
    before(:all) do
      use_api %Q{
        resource :products, actions: [:all]
      }
    end

    let!(:products) { create_list(:product, 5) }

    describe 'GET #index' do
      subject { get 'api/products' }

      it 'responds with all records' do
        subject
        expect(response.body).to eq(products.to_json)
      end
    end

    describe 'GET #show' do
      subject { get 'api/products/1' }

      it 'responds with the record' do
        subject
        expect(response.body).to eq(products.first.to_json)
      end
    end

    describe 'POST #create' do
      subject { post 'api/products', product: { title: 'hello', cost: 1900 } }

      it 'responds with the new record' do
        subject
        expect(response.body).to eq(Product.new(title: 'hello', cost: 1900).to_json)
      end
    end

    describe 'DELETE #destroy' do
      subject { delete 'api/products/1' }

      it 'responds with success' do
        expect(subject).to eq(200)
      end
    end
  end

  context 'with an access filter' do
    subject { get 'api/products/1' }

    let!(:products) { create_list(:product, 5) }

    context 'when inaccessible' do
      before(:all) do
        use_api %Q{
          resource :products do
            action(:show) { access_filter { false } }
          end
        }
      end

      it 'responds with unauthorized' do
        expect(subject).to eq(401)
      end
    end

    context 'when accessible' do
      before(:all) do
        use_api %Q{
          resource :products do
            action(:show) { access_filter { true } }
          end
        }
      end

      it 'responds with success' do
        expect(subject).to eq(200)
      end
    end
  end
end
