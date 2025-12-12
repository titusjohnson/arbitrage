# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_12_12_033557) do
  create_table "games", force: :cascade do |t|
    t.integer "current_day", default: 1, null: false
    t.integer "current_location_id"
    t.decimal "cash", precision: 10, scale: 2, default: "2000.0", null: false
    t.decimal "bank_balance", precision: 10, scale: 2, default: "0.0", null: false
    t.decimal "debt", precision: 10, scale: 2, default: "0.0", null: false
    t.string "status", default: "active", null: false
    t.integer "final_score"
    t.integer "health", default: 10, null: false
    t.integer "max_health", default: 10, null: false
    t.integer "inventory_capacity", default: 100, null: false
    t.datetime "started_at", null: false
    t.datetime "completed_at"
    t.integer "total_purchases", default: 0, null: false
    t.integer "total_sales", default: 0, null: false
    t.integer "locations_visited", default: 1, null: false
    t.decimal "best_deal_profit", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "restore_key", null: false
    t.index ["restore_key"], name: "index_games_on_restore_key", unique: true
    t.index ["started_at"], name: "index_games_on_started_at"
    t.index ["status"], name: "index_games_on_player_id_and_status"
    t.index ["status"], name: "index_games_on_status"
  end

  create_table "gutentag_taggings", force: :cascade do |t|
    t.integer "tag_id", null: false
    t.integer "taggable_id", null: false
    t.string "taggable_type", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["tag_id"], name: "index_gutentag_taggings_on_tag_id"
    t.index ["taggable_type", "taggable_id", "tag_id"], name: "unique_taggings", unique: true
    t.index ["taggable_type", "taggable_id"], name: "index_gutentag_taggings_on_taggable_type_and_taggable_id"
  end

  create_table "gutentag_tags", force: :cascade do |t|
    t.string "name", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.integer "taggings_count", default: 0, null: false
    t.index ["name"], name: "index_gutentag_tags_on_name", unique: true
    t.index ["taggings_count"], name: "index_gutentag_tags_on_taggings_count"
  end

  create_table "resources", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "base_price_min", precision: 10, scale: 2, null: false
    t.decimal "base_price_max", precision: 10, scale: 2, null: false
    t.decimal "price_volatility", precision: 5, scale: 2, default: "50.0", null: false
    t.integer "inventory_size", default: 1, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "rarity", default: "common", null: false
    t.index ["name"], name: "index_resources_on_name", unique: true
    t.index ["rarity"], name: "index_resources_on_rarity"
  end
end
