class CreateCathodeTokens < ActiveRecord::Migration
  def change
    create_table :cathode_tokens do |t|
      t.boolean :active, default: true
      t.datetime :expired_at
      t.string :token

      t.timestamps
    end
  end
end
