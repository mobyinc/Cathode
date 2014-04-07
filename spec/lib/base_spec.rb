require 'spec_helper'

describe Cathode::Base do
  describe '#resource' do
    subject { Cathode::Base.resource(:boxes, actions: [:all]) }

    it 'initializes a new resource with the params' do
      expect(Cathode::Resource).to receive(:new) do |resource_name, params|
        expect(resource_name).to eq(:boxes)
        expect(params).to eq(actions: [:all])
      end
      subject
    end
  end
end
