class CreateLocationVisits < ActiveRecord::Migration[8.0]
  def change
    create_table :location_visits do |t|
      t.references :game, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.integer :visited_on, null: false

      t.timestamps
    end

    add_index :location_visits, [:game_id, :location_id, :visited_on], name: 'index_location_visits_unique'
    add_index :location_visits, [:game_id, :visited_on], name: 'index_location_visits_on_game_and_day'
  end
end
