class AddSinePhaseOffsetToGameResources < ActiveRecord::Migration[8.0]
  def change
    # Phase offset for sinusoidal price pattern (0.0 to 2π)
    # Each resource gets a random offset so they don't all move in sync
    add_column :game_resources, :sine_phase_offset, :decimal, precision: 5, scale: 4, null: false, default: 0.0
  end
end
