class AddTrendPhaseOffsetToGameResources < ActiveRecord::Migration[8.0]
  def change
    # Phase offset for longer-term trend wave (0.0 to 2π)
    # Creates macro price momentum over 20-day cycles
    add_column :game_resources, :trend_phase_offset, :decimal, precision: 5, scale: 4, null: false, default: 0.0
  end
end
