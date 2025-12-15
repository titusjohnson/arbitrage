class DropLocationResources < ActiveRecord::Migration[8.0]
  def up
    drop_table :location_resources
  end

  def down
    create_table :location_resources do |t|
      t.references :game, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.decimal :current_price, precision: 10, scale: 2, null: false
      t.integer :last_refreshed_day, null: false
      t.integer :available_quantity, default: 100, null: false
      t.decimal :price_direction, precision: 3, scale: 2, default: 0.0, null: false
      t.decimal :price_momentum, precision: 3, scale: 2, default: 0.5, null: false
      t.decimal :base_price, precision: 10, scale: 2
      t.text :price_history
      t.timestamps

      t.index [:game_id, :location_id, :resource_id], unique: true, name: 'index_location_resources_unique'
      t.index [:game_id, :location_id], name: 'index_location_resources_on_game_and_location'
    end
  end
end
