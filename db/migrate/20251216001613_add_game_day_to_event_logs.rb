class AddGameDayToEventLogs < ActiveRecord::Migration[8.0]
  def change
    add_column :event_logs, :game_day, :integer
  end
end
