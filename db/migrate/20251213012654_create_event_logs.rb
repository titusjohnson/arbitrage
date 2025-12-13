class CreateEventLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :event_logs do |t|
      t.references :game, null: false, foreign_key: true
      t.references :loggable, polymorphic: true
      t.text :message, null: false

      t.timestamps
    end

    add_index :event_logs, [:game_id, :created_at]
  end
end
