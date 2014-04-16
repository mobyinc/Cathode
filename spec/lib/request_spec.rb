require 'spec_helper'

describe Cathode::Request do
  describe '.new' do
    subject do
      Cathode::Request.new(context_stub(headers: headers, params: params))
    end

    before do
      use_api do
        resource :products, actions: [:index]
      end
    end

    context 'without a version header' do
      let(:headers) { {} }
      let(:params) { {} }

      it 'sets status as bad request' do
        expect(subject.status).to eq(:bad_request)
      end

      it 'sets body text' do
        expect(subject.body).to eq('A version number must be passed in the Accept-Version header')
      end
    end

    context 'with an invalid version' do
      let(:headers) { { 'HTTP_ACCEPT_VERSION' => '2.0.0' } }
      let(:params) { {} }

      it 'sets status as bad request' do
        expect(subject.status).to eq(:bad_request)
      end

      it 'sets body text' do
        expect(subject.body).to eq('Unknown API version: 2.0.0')
      end
    end

    context 'with a valid version' do
      let(:headers) { { 'HTTP_ACCEPT_VERSION' => '1.0.0' } }

      context 'with an invalid action' do
        let(:params) { { controller: 'products', action: 'show' } }

        it 'sets status as not found' do
          expect(subject.status).to eq(:not_found)
        end
      end

      context 'with a valid action' do
        let(:params) { { controller: 'products', action: 'index' } }

        it 'sets status as ' do
          expect(subject.status).to eq(:ok)
        end
      end
    end
  end
end
