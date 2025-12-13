class AddPriceHistoryToLocationResources < ActiveRecord::Migration[8.0]
  def change
    # Store price history as JSON text (SQLite compatible)
    # Format: { "1": 100.50, "2": 102.25, "3": 101.75, ... }
    # Keys are day numbers, values are prices on that day
    add_column :location_resources, :price_history, :text
  end
end
