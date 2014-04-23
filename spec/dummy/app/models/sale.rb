class Sale < ActiveRecord::Base
  belongs_to :salesperson
  belongs_to :product
end
