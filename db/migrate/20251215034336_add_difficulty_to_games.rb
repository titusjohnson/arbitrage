class AddDifficultyToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :difficulty, :string, null: false, default: "street_peddler"
    add_column :games, :wealth_target, :decimal, precision: 15, scale: 2, null: false, default: 25_000
    add_column :games, :day_target, :integer, null: false, default: 30

    add_index :games, :difficulty
  end
end
