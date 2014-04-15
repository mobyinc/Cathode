require 'spec_helper'
require 'action_pack'

describe Cathode::Action do
  describe '.create' do
    subject { Cathode::Action.create(action, :products) }

    context 'with :index' do
      let(:action) { :index }

      it 'creates an IndexAction' do
        expect(subject.class).to eq(Cathode::IndexAction)
      end
    end

    context 'with :show' do
      let(:action) { :show }

      it 'creates a ShowAction' do
        expect(subject.class).to eq(Cathode::ShowAction)
      end
    end

    context 'with :create' do
      let(:action) { :create }

      it 'creates a CreateAction' do
        expect(subject.class).to eq(Cathode::CreateAction)
      end
    end

    context 'with :update' do
      let(:action) { :update }

      it 'creates an UpdateAction' do
        expect(subject.class).to eq(Cathode::UpdateAction)
      end
    end

    context 'with :destroy' do
      let(:action) { :destroy }

      it 'creates a DestroyAction' do
        expect(subject.class).to eq(Cathode::DestroyAction)
      end
    end
  end

  describe '#perform' do
    let!(:products) { [
      create(:product, title: 'battery'),
      create(:product, title: 'adapter'),
      create(:product, title: 'monitor'),
      create(:product, title: 'battery pack'),
      create(:product, title: 'charger')
    ] }

    subject { Cathode::Action.create(action, :products, &block).perform(context_stub(params)) }

    context ':index' do
      let(:action) { :index }
      let(:params) { {} }
      let(:block) { nil }

      it 'sets status as ok' do
        expect(subject[:status]).to eq(:ok)
      end

      it 'sets body as all resource records' do
        expect(subject[:body]).to eq(Product.all)
      end

      context 'with paging' do
        let(:params) { { page: 2, per_page: 2 } }

        context 'when paging is not allowed' do
          it 'responds with bad request' do
            expect(subject[:status]).to eq(:bad_request)
          end
        end

        context 'when paging is allowed' do
          let(:block) { proc do
            allows :paging
          end }

          it 'responds with the paged results' do
            expect(subject[:body]).to eq(products[2..3])
          end
        end
      end
    end

    context ':show' do
      let(:action) { :show }
      let(:params) { { :id => 3 } }

      context 'with access filter' do
        context 'when accessible' do
          let(:block) { proc { access_filter(&proc { true }) } }

          it 'sets status as ok' do
            expect(subject[:status]).to eq(:ok)
          end

          it 'sets body as the record' do
            expect(subject[:body]).to eq(products[2])
          end
        end

        context 'when inaccessible' do
          let(:block) { proc { access_filter(&proc { false }) } }

          it 'sets status as unauthorized' do
            expect(subject[:status]).to eq(:unauthorized)
          end

          it 'sets body as nil' do
            expect(subject[:body]).to be_nil
          end
        end
      end
    end

    context ':create' do
      let(:action) { :create }
      let(:params) { ActionController::Parameters.new({ product: { title: 'cool product' } }) }

      context 'when attributes specified' do
        let(:block) { proc do
          attributes do |params|
            params.require(:product).permit(:title)
          end
        end }

        it 'sets status as ok' do
          expect(subject[:status]).to eq(:ok)
        end

        it 'sets body as the new record' do
          expect(subject[:body].title).to eq('cool product')
        end
      end

      context 'when attributes not specified' do
        let(:block) { nil }

        it 'raises an error' do
          expect { subject }.to raise_error(Cathode::UnknownAttributesError, "An attributes block was not specified for `create' action on resource `products'")
        end
      end
    end

    context ':update' do
      let(:action) { :update }
      let(:params) { ActionController::Parameters.new({ id: product.id, product: { title: 'cooler product' } }) }
      let(:product) { create(:product, title: 'cool product') }

      context 'when attributes specified' do
        let(:block) { proc do
          attributes do |params|
            params.require(:product).permit(:title)
          end
        end }

        it 'sets status as ok' do
          expect(subject[:status]).to eq(:ok)
        end

        it 'sets body as the updated record' do
          expect(subject[:body].title).to eq('cooler product')
        end
      end

      context 'when attributes not specified' do
        let(:block) { nil }

        it 'raises an error' do
          expect { subject }.to raise_error(Cathode::UnknownAttributesError, "An attributes block was not specified for `create' action on resource `products'")
        end
      end
    end

    context ':destroy' do
      let(:action) { :destroy }
      let(:params) { { :id => product.id } }
      let!(:product) { create(:product) }
      let(:block) { nil }

      it 'sets status as ok' do
        expect(subject[:status]).to eq(:ok)
      end

      it 'removes the record' do
        expect { subject }.to change { Product.count }.by(-1)
      end
    end

    context 'with an override' do
      let(:action) { :show }
      let(:params) { { id: products.first.id } }
      let(:products) { create_list(:product, 2) }
      let(:block) { proc do
        override do |params|
          render json: Product.last
        end
      end }

      it 'returns the custom logic proc' do
        expect(subject[:custom_logic].class).to eq(Proc)
      end
    end
  end
end
