require 'spec_helper'

describe Cathode::Version do
  describe '.standardize' do
    subject { Cathode::Version.standardize(version) }

    context 'with integer' do
      let(:version) { 1 }

      it 'sets the semantic version' do
        expect(subject).to eq('1.0.0')
      end
    end

    context 'with float' do
      let(:version) { 1.5 }

      it 'sets the semantic version' do
        expect(subject).to eq('1.5.0')
      end
    end

    context 'with string' do
      let(:version) { '1.5.1' }

      it 'sets the semantic version' do
        expect(subject).to eq('1.5.1')
      end
    end

    context 'with prerelease' do
      let(:version) { '1.6.0-pre' }

      it 'sets the semantic version' do
        expect(subject).to eq('1.6.0-pre')
      end
    end
  end

  describe '.new' do
    subject { Cathode::Version.new(version, &block) }
    let(:version) { 1 }
    before(:each) do
      Cathode::Version.all.clear
    end

    context 'with bad version number' do
      let(:version) { 'a' }
      let(:block) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with no params or block' do
      let(:block) do
        proc do
          resource :products
        end
      end

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:products)
          expect(params).to be_nil
          expect(block).to be_nil
        end
        subject
      end
    end

    context 'with params' do
      let(:block) do
        proc do
          resource :sales, actions: [:index, :create]
        end
      end

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:sales)
          expect(params).to eq(actions: [:index, :create])
          expect(block).to be_nil
        end
        subject
      end
    end

    context 'with params and block' do
      let(:block) do
        proc do
          resource :salespeople, actions: [:index] do
            action :create
          end
        end
      end

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:salespeople)
          expect(params).to eq(actions: [:index])
          expect(block).to_not be_nil
        end
        subject
      end
    end

    context 'with inherited version' do
      before do
        Cathode::Version.new 1 do
          resource :sales, actions: [:index, :create]
        end
      end

      let(:version) { 1.5 }

      context 'with an additional resource' do
        let(:block) do
          proc do
            resource :products, actions: [:all]
          end
        end

        it 'inherits the resources from the previous version' do
          expect(subject.resources.keys).to match_array([:products, :sales])
        end
      end

      context 'with a removed resource' do
        context 'with an unkown resource' do
          let(:block) do
            proc do
              remove_resource :factories
            end
          end

          it 'raises an error' do
            expect { subject }.to raise_error(Cathode::UnknownResourceError)
          end
        end

        context 'with a single resource' do
          let(:block) do
            proc do
              resource :products, actions: [:all]
              remove_resource :sales
            end
          end

          it 'does not use the resource' do
            expect(subject.resources.keys).to match_array([:products])
          end
        end

        context 'with an array of resources' do
          before do
            Cathode::Version.new 1.2 do
              resource :products, actions: [:all]
            end
          end

          let(:block) do
            proc do
              remove_resources [:sales, :products]
            end
          end

          it 'does not use the resource' do
            expect(subject.resources.keys).to be_empty
          end
        end
      end

      context 'with a removed action' do
        context 'with an unkown action' do
          let(:block) do
            proc do
              remove_action :sales, :show
            end
          end

          it 'raises an error' do
            expect { subject }.to raise_error(Cathode::UnknownActionError)
          end
        end

        context 'with a single action' do
          let(:block) do
            proc do
              resource :products, actions: [:all]
              remove_actions :sales, :index
            end
          end

          it 'does not use the action' do
            subject
            expect(subject.resources[:sales].actions.keys).to match_array([:create])
            expect(subject.resources[:products].actions.keys).to match_array([:index, :show, :create, :update, :destroy])
          end
        end

        context 'with an array of actions' do
          let(:block) do
            proc do
              resource :products, actions: [:all]
              remove_actions :sales, [:index, :create]
            end
          end

          it 'does not use the actions' do
            subject
            expect(subject.resources[:sales].actions.keys).to match_array([])
            expect(subject.resources[:products].actions.keys).to match_array([:index, :show, :create, :update, :destroy])
          end
        end
      end
    end
  end

  describe '#resource?' do
    subject { Cathode::Version.find('1.0.0').resource?(resource) }
    before do
      use_api do
        resource :products
      end
    end

    context 'when the resource is present' do
      let(:resource) { 'products' }

      it 'is true' do
        expect(subject).to be_true
      end
    end

    context 'when the resource is not present' do
      let(:resource) { 'sales' }

      it 'is false' do
        expect(subject).to be_false
      end
    end
  end

  describe '#action?' do
    subject { Cathode::Version.find('1.0.0').action?(resource, action) }
    before do
      use_api do
        resource :products, actions: [:index]
      end
    end

    context 'when the resource is not present' do
      let(:resource) { 'sales' }
      let(:action) { 'index' }

      it 'is false' do
        expect(subject).to be_false
      end
    end

    context 'when the resource is present' do
      let(:resource) { 'products' }

      context 'when the action is present' do
        let(:action) { 'index' }

        it 'is true' do
          expect(subject).to be_true
        end
      end

      context 'when the action is not present' do
        let(:action) { 'show' }

        it 'is false' do
          expect(subject).to be_false
        end
      end
    end
  end
end
