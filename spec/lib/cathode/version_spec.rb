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

  describe '.define' do
    subject { Cathode::Version.define('1.0.0') { resources :sales } }

    context 'when version already exists' do
      before do
        use_api do
          resources :products, actions: [:index]
        end
      end

      it 'adds to the version' do
        expect(subject._resources.names).to match_array([:products, :sales])
      end
    end

    context 'when version does not exist' do
      it 'creates a new version' do
        expect(subject._resources.names).to match_array([:sales])
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
          resources :products
        end
      end

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:products)
          expect(params).to eq(singular: false)
          expect(block).to be_nil
        end
        subject
      end
    end

    context 'with params' do
      let(:block) do
        proc do
          resources :sales, actions: [:index, :create]
        end
      end

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:sales)
          expect(params).to eq(actions: [:index, :create], singular: false)
          expect(block).to be_nil
        end
        subject
      end
    end

    context 'with params and block' do
      let(:block) do
        proc do
          get :custom
          resources :sales, actions: [:index] do
            action :show
          end
        end
      end

      it 'creates the resource' do
        expect(subject._resources.names).to match_array([:sales])
      end

      it 'creates the action' do
        expect(subject.actions.names).to match_array([:custom])
      end
    end

    context 'with duplicate resource' do
      let(:block) do
        proc do
          resources :products, actions: [:index]
          resources :products, actions: [:show]
        end
      end

      it 'combines the actions' do
        expect(subject._resources.names).to match_array([:products])
        expect(subject._resources.find(:products).actions.names).to match_array([:index, :show])
      end
    end

    context 'with inherited version' do
      before do
        Cathode::Version.new 1 do
          resources :sales, actions: [:index, :show]
          get :status
        end
      end
      let(:version) { 1.5 }

      context 'with a new action' do
        let(:block) do
          proc do
            resources :sales do
              action :destroy
            end
          end
        end

        it 'inherits the actions from the previous version' do
          expect(subject._resources.names).to match_array([:sales])
          expect(subject._resources.find(:sales).actions.names).to match_array([:index, :show, :destroy])
          expect(subject.actions.names).to eq([:status])
        end

        it 'leaves the previous version intact' do
          subject
          previous_version = Cathode::Version.find('1.0.0')
          expect(previous_version._resources.find(:sales).actions.names).to match_array([:index, :show])
        end
      end

      context 'with a new resource' do
        let(:block) { proc { resources :products, actions: [:index] } }

        it 'inherits the resources from the previous version' do
          expect(subject._resources.names).to match_array([:products, :sales])
          expect(subject._resources.find(:sales).actions.names).to match_array([:index, :show])
          expect(subject._resources.find(:products).actions.names).to match_array([:index])
        end
      end

      context 'with a removed resource' do
        context 'with an unkown resource' do
          let(:block) { proc { remove_resources :factories } }

          it 'raises an error' do
            expect { subject }.to raise_error(Cathode::UnknownResourceError)
          end
        end

        context 'with a single resource' do
          let(:block) do
            proc do
              resources :products, actions: [:index]
              remove_resources :sales
            end
          end

          it 'does not use the resource' do
            expect(subject._resources.names).to match_array([:products])
          end
        end

        context 'with an array of resources' do
          before do
            Cathode::Version.new 1.2 do
              resources :products, actions: [:index]
            end
          end

          let(:block) { proc { remove_resources [:sales, :products] } }

          it 'does not use the resource' do
            expect(subject._resources.names).to be_empty
          end
        end
      end

      context 'with a removed action' do
        context 'within a resource' do
          context 'with an unknown resource' do
            let(:block) { proc { remove_action :destroy, from: :unknown } }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::UnknownResourceError,
                "Unknown resource `unknown' on ancestor version 1.0.0"
              )
            end
          end

          context 'with an unkown action' do
            let(:block) { proc { remove_action :destroy, from: :sales } }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::UnknownActionError,
                "Unknown action `destroy' on resource `sales'"
              )
            end
          end

          context 'with a single action' do
            let(:block) do
              proc do
                resources :products, actions: [:index]
                remove_action :index, from: :sales
              end
            end

            it 'does not use the action' do
              subject
              expect(subject._resources.find(:sales).actions.names).to match_array([:show])
              expect(subject._resources.find(:products).actions.names).to match_array([:index])
            end
          end

          context 'with multiple actions' do
            let(:block) do
              proc do
                resources :products, actions: [:index]
                remove_actions :index, :show, from: :sales
              end
            end

            it 'does not use the actions' do
              subject
              expect(subject._resources.find(:sales).actions.names).to match_array([])
              expect(subject._resources.find(:products).actions.names).to match_array([:index])
            end
          end
        end

        context 'outside of a resource' do
          before do
            Cathode::Version.new 1.5 do
              get :custom
              delete :custom2
            end
          end
          let(:version) { 2 }

          context 'with an unkown action' do
            let(:block) { proc { remove_action :unknown } }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::UnknownActionError,
                "Unknown action `unknown' on ancestor version 1.5.0"
              )
            end
          end

          context 'with a single action' do
            let(:block) { proc { remove_action :custom } }

            it 'removes the action' do
              expect(subject.actions.names).to match_array([:status, :custom2])
            end
          end

          context 'with multiple actions' do
            let(:block) { proc { remove_actions :custom, :custom2 } }

            it 'removes the action' do
              expect(subject.actions.names).to eq([:status])
            end
          end
        end
      end
    end
  end

  describe '.find' do
    subject { Cathode::Version.find(version_number) }
    before do
      use_api do
        resources :products
        version 1.5 do
          resources :sales
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
        resources :products
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
        resources :products, actions: [:index]
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
