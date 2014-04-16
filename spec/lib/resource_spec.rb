require 'spec_helper'

describe Cathode::Resource do
  describe '.new' do
    context 'with a nonexistent resource' do
      subject { Cathode::Resource.new(:boxes, [:all]) }

      it 'raises an error' do
        expect { subject }.to raise_error(Cathode::UnknownResourceError)
      end
    end

    context 'with all methods' do
      subject { Cathode::Resource.new(:products, actions: [:all]) }

      it 'creates a controller' do
        subject
        expect(Cathode::ProductsController).to_not be_nil
      end
    end

    context 'with subset of methods' do
      subject { Cathode::Resource.new(:products, actions: [:index, :show]) }

      it 'creates a controller' do
        subject
        expect(Cathode::ProductsController).to_not be_nil
      end
    end

    context 'with an attributes block' do
      subject do
        Cathode::Resource.new(:products, actions: actions) do
          attributes do |params|
            params.require(:product).permit(:title)
          end
        end
      end

      context 'when create is specified' do
        let(:actions) { [:create] }

        it 'sets the strong params of the action' do
          expect(subject.actions[:create].strong_params).to_not be_nil
        end
      end

      context 'when update is specified' do
        let(:actions) { [:update] }

        it 'sets the strong params of the action' do
          expect(subject.actions[:update].strong_params).to_not be_nil
        end
      end

      context 'when create and update are specified' do
        let(:actions) { [:all] }

        it 'sets the strong params of both actions' do
          expect(subject.actions[:create].strong_params).to_not be_nil
          expect(subject.actions[:update].strong_params).to_not be_nil
        end
      end

      context 'when neither create nor update is specified' do
        let(:actions) { [:index] }

        it 'raises an error' do
          expect { subject }.to raise_error(Cathode::UnknownActionError, 'An attributes block was specified without a :create or :update action')
        end
      end
    end
  end
end
