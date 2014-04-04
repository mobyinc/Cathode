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
      subject { Cathode::Resource.new(:products, [:all]) }

      it 'creates a controller' do
        subject
        expect(Cathode::ProductsController).to_not be_nil
      end
    end
  end
end
