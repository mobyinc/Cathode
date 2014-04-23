require 'spec_helper'

describe Cathode::Resource do
  describe '.new' do
    context 'with a nonexistent resource' do
      subject { Cathode::Resource.new(:boxes, :all) }

      it 'raises an error' do
        expect { subject }.to raise_error(
          Cathode::UnknownResourceError,
          "Could not find constant `Box' for resource `boxes'"
        )
      end
    end

    context 'with all methods' do
      subject { Cathode::Resource.new(:products, actions: [:index]) }

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
          expect(subject.actions.find(:create).strong_params).to_not be_nil
        end
      end

      context 'when update is specified' do
        let(:actions) { [:update] }

        it 'sets the strong params of the action' do
          expect(subject.actions.find(:update).strong_params).to_not be_nil
        end
      end

      context 'when create and update are specified' do
        let(:actions) { :all }

        it 'sets the strong params of both actions' do
          expect(subject.actions.find(:create).strong_params).to_not be_nil
          expect(subject.actions.find(:update).strong_params).to_not be_nil
        end
      end

      context 'when neither create nor update is specified' do
        let(:actions) { [:index] }

        it 'raises an error' do
          expect { subject }.to raise_error(Cathode::UnknownActionError, 'An attributes block was specified without a :create or :update action')
        end
      end
    end

    context 'with a nested resource' do
      subject do
        Cathode::Resource.new(:products) do
          resources :sales, actions: [:index, :show]
        end
      end

      it 'adds the resource' do
        expect(subject._resources.names).to match_array([:sales])
        expect(subject._resources.find(:sales).actions.names).to match_array([:index, :show])
      end
    end

    context 'with custom action' do
      subject { Cathode::Resource.new(:products, nil) { get :custom } }

      it 'sets up the action' do
        expect(subject.actions.find(:custom).http_method).to eq(:get)
      end
    end
  end

  describe 'default and custom actions' do
    let(:resource) do
      Cathode::Resource.new(:products, actions: :all) do
        get :custom
        post :custom2
        attributes {}
      end
    end

    describe '#default_actions' do
      subject { resource.default_actions }

      it 'returns the default actions' do
        expect(subject.map(&:name)).to match_array([:index, :show, :create, :update, :destroy])
      end
    end

    describe '#custom_actions' do
      subject { resource.custom_actions }

      it 'returns the custom actions' do
        expect(subject.map(&:name)).to match_array([:custom, :custom2])
      end
    end
  end
end
