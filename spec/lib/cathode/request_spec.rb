require 'spec_helper'

describe Cathode::Request do
  describe '.create' do
    subject do
      Cathode::Request.create(context_stub(
        headers: headers,
        params: ActionController::Parameters.new(params.merge(controller: 'products', action: action)),
        path: try(:path)
       ))
    end

    before do
      use_api { resource :products, actions: [:index] }
    end

    context 'without a version header' do
      let(:action) { 'index' }
      let(:headers) { {} }
      let(:params) { {} }

      it 'sets status as bad request' do
        expect(subject._status).to eq(:bad_request)
      end

      it 'sets body text' do
        expect(subject._body).to eq('A version number must be passed in the Accept-Version header')
      end
    end

    context 'with an invalid version' do
      let(:action) { 'index' }
      let(:headers) { { 'HTTP_ACCEPT_VERSION' => '2.0.0' } }
      let(:params) { {} }

      it 'sets status as bad request' do
        expect(subject._status).to eq(:bad_request)
      end

      it 'sets body text' do
        expect(subject._body).to eq('Unknown API version: 2.0.0')
      end
    end

    context 'with a valid version' do
      let(:headers) { { 'HTTP_ACCEPT_VERSION' => '1.0.0' } }

      context 'with an invalid action' do
        let(:action) { 'invalid' }
        let(:params) { {} }

        it 'sets status as not found' do
          expect(subject._status).to eq(:not_found)
        end
      end
    end
  end
end
