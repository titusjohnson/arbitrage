class CreateLocationResources < ActiveRecord::Migration[8.0]
  def change
    create_table :location_resources do |t|
      t.references :game, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.decimal :current_price, precision: 10, scale: 2, null: false
      t.integer :last_refreshed_day, null: false

      t.timestamps
    end

    # Ensure unique resources per location per game (fog of war is game-specific)
    add_index :location_resources, [:game_id, :location_id, :resource_id], unique: true, name: 'index_location_resources_unique'

    # Query optimization for common lookups
    add_index :location_resources, [:game_id, :location_id], name: 'index_location_resources_on_game_and_location'
  end
end
