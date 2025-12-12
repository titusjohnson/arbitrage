class CreateLocations < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name, null: false
      t.text :description
      t.integer :x, null: false
      t.integer :y, null: false

      t.timestamps
    end

    add_index :locations, [:x, :y], unique: true
  end
end
