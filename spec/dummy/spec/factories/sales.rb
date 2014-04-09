# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :sale, :class => 'Sale' do
    product_id 1
    subtotal 1
    taxes 1
  end
end
