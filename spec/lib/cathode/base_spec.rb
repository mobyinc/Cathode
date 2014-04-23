require 'spec_helper'

describe Cathode::Base do
  describe '#version' do
    subject do
      Cathode::Base.version 1.5 do
        resources :products
      end
    end

    it 'creates a new version' do
      expect(subject.version).to eq('1.5.0')
    end

    it 'contains the resources' do
      expect(subject._resources.names).to eq([:products])
    end
  end

  describe '#define' do
    context 'with resource name' do
      subject do
        Cathode::Base.define do
          resources :products
        end
      end

      it 'initializes version 1.0.0' do
        subject
        expect(Cathode::Version.find('1.0.0')._resources.find(:products)).to_not be_nil
      end
    end
  end
end
