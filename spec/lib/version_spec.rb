require 'spec_helper'

describe Cathode::Version do
  describe '.standardize' do
    subject { Cathode::Version.standardize(version) }

    context 'with integer' do
      let(:version) { 1 }

      it 'sets the semantic version' do
        expect(subject).to eq('1.0.0')
      end
    end

    context 'with float' do
      let(:version) { 1.5 }

      it 'sets the semantic version' do
        expect(subject).to eq('1.5.0')
      end
    end

    context 'with string' do
      let(:version) { '1.5.1' }

      it 'sets the semantic version' do
        expect(subject).to eq('1.5.1')
      end
    end

    context 'with prerelease' do
      let(:version) { '1.6.0-pre' }

      it 'sets the semantic version' do
        expect(subject).to eq('1.6.0-pre')
      end
    end
  end

  describe '.new' do
    subject { Cathode::Version.new(version, &block) }
    let(:version) { 1 }
    before(:each) do
      Cathode::Version.all.clear
    end

    context 'with bad version number' do
      let(:version) { 'a' }
      let(:block) { nil }

      it 'raises an error' do
        expect { subject }.to raise_error(ArgumentError)
      end
    end

    context 'with no params or block' do
      let(:block) { proc do
        resource :products
      end }

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:products)
          expect(params).to be_nil
          expect(block).to be_nil
        end
        subject
      end
    end

    context 'with params' do
      let(:block) { proc do
        resource :sales, actions: [:index, :create]
      end }

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:sales)
          expect(params).to eq(actions: [:index, :create])
          expect(block).to be_nil
        end
        subject
      end
    end

    context 'with params and block' do
      let(:block) { proc do
        resource :salespeople, actions: [:index] do
          action :create
        end
      end }

      it 'creates the resource' do
        expect(Cathode::Resource).to receive(:new) do |resource, params, &block|
          expect(resource).to eq(:salespeople)
          expect(params).to eq(actions: [:index])
          expect(block).to_not be_nil
        end
        subject
      end
    end

    context 'with inherited version' do
      before do
        Cathode::Version.new 1 do
          resource :sales, actions: [:index, :create]
        end
      end

      let(:version) { 1.5 }

      context 'with an additional resource' do
        let(:block) { proc do
          resource :products, actions: [:all]
        end }

        it 'inherits the resources from the previous version' do
          expect(subject.resources.keys).to match_array([:products, :sales])
        end
      end

      context 'with a removed resource' do
        let(:block) { proc do
          resource :products, actions: [:all]
          remove_resource :sales
        end }

        it 'does not use the resource' do
          expect(subject.resources.keys).to match_array([:products])
        end
      end
    end
  end
end
