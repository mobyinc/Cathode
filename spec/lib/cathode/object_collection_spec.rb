require 'spec_helper'

describe Cathode::ObjectCollection do
  let(:collection) { Cathode::ObjectCollection.new }
  let(:obj_struct) { Struct.new(:name) }
  let(:battery) { obj_struct.new(:battery) }
  let(:charger) { obj_struct.new(:charger) }
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

  describe '#add' do
    subject { collection.add(items) }
    let(:cord) { obj_struct.new(:cord) }
    let(:connector) { obj_struct.new(:connector) }

    context 'with single item' do
      let(:items) { cord }

      it 'adds the item to the objects' do
        expect(subject.objects).to match_array([battery, charger, cord])
      end
    end

    context 'with an array of items' do
      let(:items) { [cord, connector] }

      it 'adds the items to the objects' do
        expect(subject.objects).to match_array([battery, charger, cord, connector])
      end
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
