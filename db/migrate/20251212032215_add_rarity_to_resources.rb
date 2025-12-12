class AddRarityToResources < ActiveRecord::Migration[8.0]
  def change
    add_column :resources, :rarity, :string, null: false, default: "common"
    add_index :resources, :rarity
  end
end
