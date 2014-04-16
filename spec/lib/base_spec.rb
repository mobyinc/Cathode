require 'spec_helper'

describe Cathode::Base do
  describe '#version' do
    subject { Cathode::Base.version 1.5 do
      resource :products
    end }

    it 'creates a new version' do
      expect(subject.version).to eq('1.5.0')
    end

    it 'contains the resources' do
      expect(subject.resources.keys).to eq([:products])
    end
  end

  describe '#define' do
    context 'with resource name' do
      subject { Cathode::Base.define do
        resource :products
      end }

      it 'initializes version 1.0.0' do
        subject
        expect(Cathode::Version.all['1.0.0'].resources[:products]).to_not be_nil
      end
    end
  end
end
