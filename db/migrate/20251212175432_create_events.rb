class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.string :name, null: false
      t.text :description
      t.integer :day_start
      t.integer :duration
      t.boolean :active, default: false
      t.json :resource_effects
      t.json :location_effects
      t.string :event_type
      t.integer :severity
      t.string :rarity

      t.timestamps
    end
  end
end
