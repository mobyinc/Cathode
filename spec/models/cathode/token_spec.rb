require 'spec_helper'

describe Cathode::Token do
  describe '.new' do
    subject { Cathode::Token.new }

    it 'generates a token' do
      expect(subject.token).to_not be_nil
    end

    it 'activates the token' do
      expect(subject.active).to be_true
    end
  end

  describe 'validations' do
    describe 'unique tokens' do
      subject { token1.update(token: token) }
      let(:token1) { create(:token) }
      let(:token2) { create(:token) }

      context 'with a used token' do
        let(:token) { token2.token }

        it 'does not update the token' do
          expect(subject).to be_false
        end
      end

      context 'with an unused token' do
        let(:token) { SecureRandom.hex }

        it 'updates the token' do
          expect(subject).to be_true
        end
      end
    end
  end

  describe '#expire' do
    subject { token.expire }

    context 'when the token is active' do
      let(:token) { Cathode::Token.new }

      it 'expires the token' do
        Timecop.freeze do
          expect(subject.active).to be_false
          expect(subject.expired_at).to eq(Time.now)
        end
      end
    end

    context 'when the token is already expired' do
      let(:token) { Cathode::Token.new(active: false, expired_at: Time.now) }

      it 'leaves active false' do
        expect(subject.active).to be_false
      end
    end
  end
end
