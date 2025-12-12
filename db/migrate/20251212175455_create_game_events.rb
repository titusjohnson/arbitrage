class CreateGameEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :game_events do |t|
      t.references :game, null: false, foreign_key: true
      t.references :event, null: false, foreign_key: true
      t.integer :day_triggered
      t.integer :days_remaining
      t.boolean :seen, default: false

      t.timestamps
    end
  end
end
