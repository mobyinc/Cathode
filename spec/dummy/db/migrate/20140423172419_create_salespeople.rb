class CreateSalespeople < ActiveRecord::Migration
  def change
    create_table :salespeople do |t|
      t.string :name

      t.timestamps
    end

    add_column :sales, :salesperson_id, :integer
  end
end
