require 'spec_helper'

describe Cathode::ActionRequest do
  describe '.new' do
    subject { Cathode::ActionRequest.new(action, context, &block) }
    let!(:products) { create_list(:product, 2) }

    describe 'block' do
      let(:action) { nil }
      let(:context) { nil }

      context 'with blocks for body/status' do
        let(:block) do
          proc do
            body { Product.last }
            status { :ok }
          end
        end

        it 'sets the status' do
          expect(subject._status).to eq(:ok)
        end

        it 'sets the body' do
          expect(subject._body).to eq(Product.last)
        end
      end

      context 'with values for body/status' do
        let(:block) do
          proc do
            body Product.last
            status :ok
          end
        end

        it 'sets the status' do
          expect(subject._status).to eq(:ok)
        end

        it 'sets the body' do
          expect(subject._body).to eq(Product.last)
        end
      end
    end

    describe 'actions' do
      subject { Cathode::ActionRequest.new(context_stub(params: {}), nil) }

      context ':index' do
        it 'sets the status' do
          expect(subject._status).to eq(:ok)
        end
      end
    end
  end
end
