class CreateInventoryItems < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_items do |t|
      t.references :game, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.decimal :purchase_price, precision: 10, scale: 2, null: false
      t.integer :purchase_day, null: false
      t.integer :purchase_location_id

      t.timestamps
    end

    add_index :inventory_items, [:game_id, :resource_id]
  end
end
