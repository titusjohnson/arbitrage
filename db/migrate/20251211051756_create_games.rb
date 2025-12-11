class CreateGames < ActiveRecord::Migration[8.0]
  def change
    create_table :games do |t|
      # Player relationship (references users table)
      t.references :player, null: false, foreign_key: { to_table: :users }

      # Game progress
      t.integer :current_day, null: false, default: 1
      t.integer :current_location_id # Will reference locations table when created

      # Financial state (precision: 10, scale: 2 for currency)
      t.decimal :cash, precision: 10, scale: 2, null: false, default: 2000.00
      t.decimal :bank_balance, precision: 10, scale: 2, null: false, default: 0.00
      t.decimal :debt, precision: 10, scale: 2, null: false, default: 0.00

      # Game state
      t.string :status, null: false, default: "active"
      t.integer :final_score
      t.integer :health, null: false, default: 10
      t.integer :max_health, null: false, default: 10
      t.integer :inventory_capacity, null: false, default: 100

      # Game lifecycle timestamps
      t.datetime :started_at, null: false
      t.datetime :completed_at

      # Statistics
      t.integer :total_purchases, null: false, default: 0
      t.integer :total_sales, null: false, default: 0
      t.integer :locations_visited, null: false, default: 1
      t.decimal :best_deal_profit, precision: 10, scale: 2, null: false, default: 0.00

      t.timestamps
    end

    # Indexes for common queries
    add_index :games, [:player_id, :status]
    add_index :games, :status
    add_index :games, :started_at
  end
end
