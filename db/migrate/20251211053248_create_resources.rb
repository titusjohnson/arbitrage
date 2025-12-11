class CreateResources < ActiveRecord::Migration[8.0]
  def change
    create_table :resources do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :base_price_min, precision: 10, scale: 2, null: false
      t.decimal :base_price_max, precision: 10, scale: 2, null: false
      t.decimal :price_volatility, precision: 5, scale: 2, null: false, default: 50.00
      t.integer :inventory_size, null: false, default: 1

      t.timestamps
    end

    add_index :resources, :name, unique: true
  end
end
