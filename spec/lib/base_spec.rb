require 'spec_helper'

describe Cathode::Base do
  describe '#resource' do
    context 'with resource name' do
      subject { Cathode::Base.resource(:boxes) }

      it 'initializes a new resource with no params' do
        expect(Cathode::Resource).to receive(:new) do |resource_name|
          expect(resource_name).to eq(:boxes)
        end
        subject
      end
    end

    context 'with resource name and params' do
      subject { Cathode::Base.resource(:boxes, actions: [:all]) }

      it 'initializes a new resource with the params' do
        expect(Cathode::Resource).to receive(:new) do |resource_name, params|
          expect(resource_name).to eq(:boxes)
          expect(params).to eq(actions: [:all])
        end
        subject
      end
    end

    context 'with resource name and block' do
      subject { Cathode::Base.resource(:boxes) { action :index } }

      it 'initializes a new resource with the block' do
        expect(Cathode::Resource).to receive(:new) do |resource_name, params, &block|
          expect(resource_name).to eq(:boxes)
          expect(params).to eq(nil)
          expect(block.is_a?(Proc)).to be_true
        end
        subject
      end
    end

    context 'with resource name, params, and block' do
      subject { Cathode::Base.resource(:boxes, actions: [:all]) { action :index } }

      it 'initializes a new resource with the params and block' do
        expect(Cathode::Resource).to receive(:new) do |resource_name, params, &block|
          expect(resource_name).to eq(:boxes)
          expect(params).to eq(actions: [:all])
          expect(block.is_a?(Proc)).to be_true
        end
        subject
      end
    end
  end
end
