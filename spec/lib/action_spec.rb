require 'spec_helper'

describe Cathode::Action do
  describe '.new' do
    subject { Cathode::Action.new(:products, &block) }

    context 'with access filter' do
      let(:block) { proc { access_filter(&proc { true }) } }

      context 'when accessible' do
        it 'sets the access filter' do
          expect(subject.action_access_filter.call).to be_true
        end
      end
    end
  end
end
