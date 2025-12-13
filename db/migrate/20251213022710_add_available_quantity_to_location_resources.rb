class AddAvailableQuantityToLocationResources < ActiveRecord::Migration[8.0]
  def change
    add_column :location_resources, :available_quantity, :integer, null: false, default: 100
  end
end
