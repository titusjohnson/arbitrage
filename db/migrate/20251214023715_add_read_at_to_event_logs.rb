class AddReadAtToEventLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :event_logs, :read_at, :datetime
    add_index :event_logs, [:game_id, :read_at]
  end
end
