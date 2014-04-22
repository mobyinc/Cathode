require 'spec_helper'

describe Cathode::ObjectCollection do
  let(:collection) { Cathode::ObjectCollection.new }
  let(:battery) { Struct.new(:name).new(:battery) }
  let(:charger) { Struct.new(:name).new(:charger) }
  before do
    collection << battery
    collection << charger
  end

  describe '#find' do
    subject { collection.find(:battery) }

    it 'returns the item with the matching name' do
      expect(subject).to eq(battery)
    end
  end

  describe '#delete' do
    subject { collection.delete(:battery) }

    it 'deletes the object from the collection' do
      expect(subject.objects).to match_array([charger])
    end
  end

  describe '#names' do
    subject { collection.names }

    it 'returns the objects mapped to their names' do
      expect(subject).to match_array([:battery, :charger])
    end
  end

  describe 'array methods' do
    subject { collection.each { |i| i } }

    it 'delegates to the object array' do
      expect(subject).to match_array([battery, charger])
    end
  end
end
