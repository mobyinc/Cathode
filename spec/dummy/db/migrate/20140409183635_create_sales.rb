class CreateSales < ActiveRecord::Migration
  def change
    create_table :sales do |t|
      t.integer :product_id
      t.integer :subtotal
      t.integer :taxes

      t.timestamps
    end
  end
end
