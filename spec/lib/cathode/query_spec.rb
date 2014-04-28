require 'spec_helper'

describe Cathode::Query do
  describe '.new' do
    subject { Cathode::Query.new(Product, query) }
    let!(:product1) { create(:product, cost: 500) }
    let!(:product2) { create(:product, cost: 700) }
    let!(:product3) { create(:product, cost: 1000) }

    describe 'where' do
      context 'explicit' do
        let(:query) { 'where cost > 500' }

        it 'returns the records' do
          expect(subject.results).to match_array([product2, product3])
        end
      end

      context 'implicit' do
        let(:query) { 'cost > 500' }

        it 'returns the records' do
          expect(subject.results).to match_array([product2, product3])
        end
      end
    end
  end
end
