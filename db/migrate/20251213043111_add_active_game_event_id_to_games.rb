class AddActiveGameEventIdToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :active_game_event_id, :integer
    add_index :games, :active_game_event_id
    add_foreign_key :games, :game_events, column: :active_game_event_id
  end
end
