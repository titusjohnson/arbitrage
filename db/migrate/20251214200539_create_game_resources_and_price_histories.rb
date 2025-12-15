class CreateGameResourcesAndPriceHistories < ActiveRecord::Migration[8.0]
  def change
    # Create game_resources table (replaces location_resources)
    create_table :game_resources do |t|
      t.references :game, null: false, foreign_key: true
      t.references :resource, null: false, foreign_key: true
      t.decimal :current_price, precision: 10, scale: 2, null: false
      t.decimal :base_price, precision: 10, scale: 2, null: false
      t.integer :available_quantity, default: 100, null: false
      t.decimal :price_direction, precision: 3, scale: 2, default: 0.0, null: false
      t.decimal :price_momentum, precision: 3, scale: 2, default: 0.5, null: false
      t.integer :last_refreshed_day, null: false
      t.timestamps

      t.index [:game_id, :resource_id], unique: true, name: 'index_game_resources_unique'
    end

    # Create resource_price_histories table for daily price tracking
    create_table :resource_price_histories do |t|
      t.references :game_resource, null: false, foreign_key: true
      t.integer :day, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :quantity, null: false
      t.timestamps

      t.index [:game_resource_id, :day], unique: true, name: 'index_price_histories_unique'
      t.index [:game_resource_id, :day, :price], name: 'index_price_histories_for_analysis'
    end
  end
end
