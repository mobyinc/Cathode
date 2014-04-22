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

    context 'with duplicate resource' do
      let(:block) do
        proc do
          resource :products, actions: [:index]
          resource :products, actions: [:create]
        end
      end

      it 'raises an error' do
        expect { subject }.to raise_error(
          Cathode::DuplicateResourceError,
          "Resource `products' already defined on version 1.0.0"
        )
      end
    end

    context 'with inherited version' do
      before do
        Cathode::Version.new 1 do
          resource :sales, actions: [:index, :show]
        end
      end

      let(:version) { 1.5 }

      context 'with a new action' do
        let(:block) { proc { resource :sales { action :destroy } } }

        it 'inherits the resources from the previous version' do
          expect(subject.resources.names).to match_array([:sales])
          expect(subject.resources.find(:sales).actions.names).to match_array([:index, :show, :destroy])
        end
      end

      context 'with an additional resource' do
        let(:block) do
          proc do
            resource :products, actions: [:index]
          end
        end

        it 'inherits the resources from the previous version' do
          expect(subject.resources.names).to match_array([:products, :sales])
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
              resource :products, actions: [:index]
              remove_resource :sales
            end
          end

          it 'does not use the resource' do
            expect(subject.resources.names).to match_array([:products])
          end
        end

        context 'with an array of resources' do
          before do
            Cathode::Version.new 1.2 do
              resource :products, actions: [:index]
            end
          end

          let(:block) do
            proc do
              remove_resources [:sales, :products]
            end
          end

          it 'does not use the resource' do
            expect(subject.resources.names).to be_empty
          end
        end
      end

      context 'with a removed action' do
        context 'with an unkown action' do
          let(:block) do
            proc do
              remove_action :sales, :destroy
            end
          end

          it 'raises an error' do
            expect { subject }.to raise_error(Cathode::UnknownActionError)
          end
        end

        context 'with a single action' do
          let(:block) do
            proc do
              resource :products, actions: [:index]
              remove_actions :sales, :index
            end
          end

          it 'does not use the action' do
            subject
            expect(subject.resources.find(:sales).actions.names).to match_array([:show])
            expect(subject.resources.find(:products).actions.names).to match_array([:index])
          end
        end

        context 'with an array of actions' do
          let(:block) do
            proc do
              resource :products, actions: [:index]
              remove_actions :sales, [:index, :show]
            end
          end

          it 'does not use the actions' do
            subject
            expect(subject.resources.find(:sales).actions.names).to match_array([])
            expect(subject.resources.find(:products).actions.names).to match_array([:index])
          end
        end
      end
    end
  end

  describe '.find' do
    subject { Cathode::Version.find(version_number) }
    before do
      use_api do
        resource :products
        version 1.5 do
          resource :sales
        end
      end
    end

    context 'with a valid SemVer number' do
      let(:version_number) { '1.5.0' }

      it 'returns the version matching the version number' do
        expect(subject.version).to eq('1.5.0')
      end
    end

    context 'with a non-standard SemVer number' do
      let(:version_number) { '1.5' }

      it 'returns the version matching the standardized number' do
        expect(subject.version).to eq('1.5.0')
      end
    end

    context 'with an invalid SemVer number' do
      let(:version_number) { '1.x' }

      it 'returns nil' do
        expect(subject).to be_nil
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
