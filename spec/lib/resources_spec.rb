require 'spec_helper'

describe 'Resources' do
  context 'with a nonexistent resource' do
    subject { Class.new(Cathode::Base) { resource :boxes, actions: [:all] } }

    it 'throws an error' do
      expect { subject }.to raise_error(NameError)
    end
  end

  context 'with an existing resource' do
    before do
      Rails::Application.class_eval 'class Product < ActiveRecord::Base; end'
    end

    subject { Class.new(Cathode::Base) { resource :products, actions: [:all] } }

    it 'creates a controller' do
      subject
      expect(Cathode::ProductsController).to_not be_nil
    end
  end
end
