class AddPopulationToLocations < ActiveRecord::Migration[8.0]
  def change
    add_column :locations, :population, :integer, null: false, default: 0
  end
end
