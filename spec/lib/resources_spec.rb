require 'spec_helper'

describe Cathode::Resource do
  describe '.new' do
    context 'with a nonexistent resource' do
      subject { Cathode::Resource.new(:boxes, [:all]) }

      it 'raises an error' do
        expect { subject }.to raise_error(Cathode::UnknownResourceError)
      end
    end

    context 'with an existing resource' do
      context 'with all methods' do
        subject { Cathode::Resource.new(:products, actions: [:all]) }

        it 'creates a controller' do
          subject
          expect(Cathode::ProductsController).to_not be_nil
        end

        it 'adds index, create, update, show, delete routes' do
          subject
          expect(Cathode::Engine.routes.recognize_path('products', method: :get)).to be_true
          expect(Cathode::Engine.routes.recognize_path('products/1', method: :get)).to be_true
          expect(Cathode::Engine.routes.recognize_path('products', method: :post)).to be_true
          expect(Cathode::Engine.routes.recognize_path('products/1', method: :put)).to be_true
          expect(Cathode::Engine.routes.recognize_path('products/1', method: :delete)).to be_true
        end

        it 'does not add the edit route' do
          expect { Cathode::Engine.routes.recognize_path('products/1/edit', method: :get) }.to raise_error
        end
      end

      context 'with subset of methods' do
        subject { Cathode::Resource.new(:products, actions: [:index, :show]) }

        it 'creates a controller' do
          subject
          expect(Cathode::ProductsController).to_not be_nil
        end

        it 'adds routes only for the defined actions' do
          subject
          expect(Cathode::Engine.routes.recognize_path('products', method: :get)).to be_true
          expect(Cathode::Engine.routes.recognize_path('products/1', method: :get)).to be_true
        end

        it 'does not add the other routes' do
          subject
          expect { Cathode::Engine.routes.recognize_path('products/1/edit', method: :get) }.to raise_error
          expect { Cathode::Engine.routes.recognize_path('products', method: :post) }.to raise_error
          expect { Cathode::Engine.routes.recognize_path('products/1', method: :put) }.to raise_error
          expect { Cathode::Engine.routes.recognize_path('products/1', method: :delete) }.to raise_error
        end
      end

      context 'with a block action' do
        subject { Cathode::Resource.new(:products, &block) }

        context 'and plain actions' do
          let(:block) { proc { action :index } }

          it 'adds the route' do
            subject
            expect(Cathode::Engine.routes.recognize_path('products', method: :get)).to be_true
          end

          it 'does not add other actions' do
            subject
            expect { Cathode::Engine.routes.recognize_path('products', method: :post) }.to raise_error
          end
        end
      end
    end
  end
end
