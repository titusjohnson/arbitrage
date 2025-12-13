class ChangeGameDefaultCash < ActiveRecord::Migration[8.0]
  def change
    # Based on statistical analysis: $3,300 gives 50% chance to fill 50% inventory in 2 turns
    # Using $5,000 for a more balanced experience (between recommended $3,300 and conservative $4,300)
    change_column_default :games, :cash, from: 2000.00, to: 5000.00
  end
end
