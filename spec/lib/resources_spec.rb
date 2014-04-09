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
      end

      context 'with subset of methods' do
        subject { Cathode::Resource.new(:products, actions: [:index, :show]) }

        it 'creates a controller' do
          subject
          expect(Cathode::ProductsController).to_not be_nil
        end
      end
    end
  end
end
