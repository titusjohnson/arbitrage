class CreateBuddies < ActiveRecord::Migration[8.0]
  def change
    create_table :buddies do |t|
      t.references :game, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true
      t.references :resource, foreign_key: true # nullable until assigned

      t.string :name, null: false
      t.integer :hire_cost, null: false, default: 100
      t.integer :hire_day, null: false

      # Resource holding details
      t.integer :quantity, default: 0
      t.decimal :purchase_price, precision: 10, scale: 2
      t.integer :target_profit_percent, default: 25

      # Status tracking
      t.string :status, default: 'idle', null: false

      # Sale results
      t.decimal :last_sale_profit, precision: 10, scale: 2
      t.integer :last_sale_day

      t.timestamps
    end

    add_index :buddies, [:game_id, :location_id]
    add_index :buddies, [:game_id, :status]
  end
end
