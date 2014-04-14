require 'spec_helper'

describe Cathode::Version do
  describe '.new' do
    subject { Cathode::Version.new(version, &block) }

    describe 'creation of semvers with flexible version input' do
      let(:block) { nil }

      context 'with bad version number' do
        let(:version) { 'a' }

        it 'raises an error' do
          expect { subject }.to raise_error(ArgumentError)
        end
      end

      context 'with good version' do
        context 'with integer' do
          let(:version) { 1 }

          it 'sets the semantic version' do
            expect(subject.version).to eq('1.0.0')
          end
        end

        context 'with float' do
          let(:version) { 1.5 }

          it 'sets the semantic version' do
            expect(subject.version).to eq('1.5.0')
          end
        end

        context 'with string' do
          let(:version) { '1.5.1' }

          it 'sets the semantic version' do
            expect(subject.version).to eq('1.5.1')
          end
        end

        context 'with prerelease' do
          let(:version) { '1.6.0-pre' }

          it 'sets the semantic version' do
            expect(subject.version).to eq('1.6.0-pre')
          end
        end
      end
    end

    describe 'creation of resources' do
      let(:version) { 1 }

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
    end
  end
end
