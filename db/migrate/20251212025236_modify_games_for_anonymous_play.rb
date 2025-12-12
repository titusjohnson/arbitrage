class ModifyGamesForAnonymousPlay < ActiveRecord::Migration[8.0]
  def change
    # Remove the foreign key constraint
    remove_foreign_key :games, :users, column: :player_id

    # Remove the player_id column
    remove_column :games, :player_id, :integer

    # Add restore_key column with unique index
    add_column :games, :restore_key, :string, null: false
    add_index :games, :restore_key, unique: true
  end
end
