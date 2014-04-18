require 'spec_helper'

describe Cathode::Action do
  describe '.create' do
    subject { Cathode::Action.create(action, :products, &block) }

    context 'with a default action' do
      let(:action) { :index }

      context 'with an override' do
        let(:block) { proc { override { Product.last } } }

        it 'sets the override as the action block' do
          expect(subject.action_block.call).to eq(Product.last)
        end
      end
    end

    context 'with a custom action' do
      let(:action) { :custom }
      let(:block) { proc { Product.last } }

      it 'creates a CustomAction' do
        expect(subject.class).to eq(Cathode::CustomAction)
      end

      it 'sets the block as the action block' do
        expect(subject.action_block.call).to eq(Product.last)
      end
    end

    context 'with :index' do
      let(:action) { :index }
      let(:block) { nil }

      it 'creates an IndexAction' do
        expect(subject.class).to eq(Cathode::IndexAction)
      end
    end

    context 'with :show' do
      let(:action) { :show }
      let(:block) { nil }

      it 'creates a ShowAction' do
        expect(subject.class).to eq(Cathode::ShowAction)
      end
    end

    context 'with :create' do
      let(:action) { :create }

      context 'when attributes specified' do
        let(:block) do
          proc { attributes { params.require(:product) } }
        end

        it 'creates a CreateAction' do
          expect(subject.after_resource_initialized.class).to eq(Cathode::CreateAction)
        end
      end

      context 'when attributes not specified' do
        let(:block) { nil }

        it 'raises an error' do
          expect { subject.after_resource_initialized }.to raise_error(
            Cathode::UnknownAttributesError,
            "An attributes block was not specified for `create' action on resource `products'"
          )
        end
      end
    end

    context 'with :update' do
      let(:action) { :update }

      context 'when attributes specified' do
        let(:block) do
          proc { attributes { params.require(:product) } }
        end

        it 'creates an UpdateAction' do
          expect(subject.after_resource_initialized.class).to eq(Cathode::UpdateAction)
        end
      end

      context 'when attributes not specified' do
        let(:block) { nil }

        it 'raises an error' do
          expect { subject.after_resource_initialized }.to raise_error(
            Cathode::UnknownAttributesError,
            "An attributes block was not specified for `update' action on resource `products'"
           )
        end
      end
    end

    context 'with :destroy' do
      let(:action) { :destroy }
      let(:block) { nil }

      it 'creates a DestroyAction' do
        expect(subject.class).to eq(Cathode::DestroyAction)
      end
    end
  end
end
