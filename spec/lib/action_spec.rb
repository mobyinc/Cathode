require 'spec_helper'

describe Cathode::Action do
  describe '.new' do
    subject { Cathode::Action.create(:show, :products, &block) }

    context 'with access filter' do
      let(:block) { proc { access_filter(&proc { true }) } }

      it 'sets the access filter' do
        expect(subject.action_access_filter.call).to be_true
      end
    end
  end

  describe '#perform' do
    let!(:product) { create(:product) }

    subject { Cathode::Action.create(:show, :products, &block).perform(:id => 1) }

    context 'with access filter' do
      context 'when accessible' do
        let(:block) { proc { access_filter(&proc { true }) } }

        it 'sets status as ok' do
          expect(subject[:status]).to eq(:ok)
        end
      end

      context 'when inaccessible' do
        let(:block) { proc { access_filter(&proc { false }) } }

        it 'sets status as unauthorized' do
          expect(subject[:status]).to eq(:unauthorized)
        end
      end
    end
  end
end
