require 'spec_helper'

describe Cathode::Action do
  describe '.create' do
    subject { Cathode::Action.create(action, :products) }

    context 'with :index' do
      let(:action) { :index }

      it 'creates a IndexAction' do
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
    let!(:products) { create_list(:product, 5) }

    subject { Cathode::Action.create(action, :products, &block).perform(params) }

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
  end
end
