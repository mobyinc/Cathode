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

    context 'with a singular resource' do
      [:index, :create, :update, :show].each do |action|
        context action do
          subject do
            resource = proc do |action, override|
              Cathode::Resource.new(:product, singular: true) do
                if override
                  override_action(action) { head :ok }
                else
                  action(action)
                end

                if [:create, :update].include? action
                  attributes {}
                end
              end
            end
            resource.call(action, override)
          end

          context 'with custom behavior' do
            let(:override) { true }

            it 'creates the action' do
              expect(subject.actions.names).to eq([action])
            end
          end

          describe 'with default behavior' do
            let(:override) { false }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::ActionBehaviorMissingError,
                "Can't use default :#{action} action on singular resource `product'"
              )
            end
          end
        end
      end

      context 'custom' do
        subject do
          Cathode::Resource.new(:product, singular: true) do
            get :custom do
              head :ok
            end
          end
        end

        it 'creates the action' do
          expect(subject.actions.names).to eq([:custom])
        end
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
        block = proc do |subresource, plural, default, action|
          method = plural ? :resources : :resource

          proc do
            send method, subresource do
              if default
                action action
              else
                override_action action do
                  body 'hello'
                end
              end
              if [:create, :update].include? action
                attributes {}
              end
            end
          end
        end
        Cathode::Resource.new(resource, &block.call(subresource, plural, default, action))
      end
      let(:resource) { :products }

      context 'with a has_many association' do
        let(:plural) { true }
        let(:subresource) { :sales }

        context ':index' do
          let(:action) { :index }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:index])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:index])
            end
          end
        end

        context ':show' do
          let(:action) { :show }

          context 'with default behavior' do
            let(:default) { true }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::MissingAssociationError,
                "Can't use default :show action on `products' without a has_one `sale' association"
              )
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:show])
            end
          end
        end

        context ':create' do
          let(:action) { :create }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:create])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:create])
            end
          end
        end

        context ':update' do
          let(:action) { :update }

          context 'with default behavior' do
            let(:default) { true }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::MissingAssociationError,
                "Can't use default :update action on `products' without a has_one `sale' association"
              )
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:update])
            end
          end
        end

        context ':destroy' do
          let(:action) { :destroy }

          context 'with default behavior' do
            let(:default) { true }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::MissingAssociationError,
                "Can't use default :destroy action on `products' without a has_one `sale' association"
              )
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sales])
              expect(subject._resources.find(:sales).actions.names).to match_array([:destroy])
            end
          end
        end
      end

      context 'with a has_one association' do
        let(:resource) { :sales }
        let(:subresource) { :payment }
        let(:plural) { false }

        context ':index' do
          let(:action) { :index }

          context 'with default behavior' do
            let(:default) { true }

            it 'raises an error' do
              expect { subject }.to raise_error(
                Cathode::MissingAssociationError,
                "Can't use default :index action on `sales' without a has_many or has_and_belongs_to_many `payment' association"
              )
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:index])
            end
          end
        end

        context ':show' do
          let(:action) { :show }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:show])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:show])
            end
          end
        end

        context ':create' do
          let(:action) { :create }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:create])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:create])
            end
          end
        end

        context ':update' do
          let(:action) { :update }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:update])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:update])
            end
          end
        end

        context ':destroy' do
          let(:action) { :destroy }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:destroy])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:payment])
              expect(subject._resources.find(:payment).actions.names).to match_array([:destroy])
            end
          end
        end
      end

      context 'with a belongs_to association' do
        let(:resource) { :payments }
        let(:subresource) { :sale }
        let(:plural) { false }

        context ':show' do
          let(:action) { :show }

          context 'with default behavior' do
            let(:default) { true }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sale])
              expect(subject._resources.find(:sale).actions.names).to match_array([:show])
            end
          end

          context 'with custom behavior' do
            let(:default) { false }

            it 'adds the resource' do
              expect(subject._resources.names).to match_array([:sale])
              expect(subject._resources.find(:sale).actions.names).to match_array([:show])
            end
          end
        end
      end

      context 'with a has_many:through association' do pending end

      context 'with a has_and_belongs_to_many association' do pending end

      context 'with no association' do pending end
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
