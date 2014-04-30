FactoryGirl.define do
  factory :product do
    sequence :title do |n|
      "Product #{n}"
    end
  end
end
