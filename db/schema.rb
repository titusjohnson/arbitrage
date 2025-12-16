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

ActiveRecord::Schema[8.0].define(version: 2025_12_16_001613) do
  create_table "buddies", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "location_id", null: false
    t.integer "resource_id"
    t.string "name", null: false
    t.integer "hire_cost", default: 100, null: false
    t.integer "hire_day", null: false
    t.integer "quantity", default: 0
    t.decimal "purchase_price", precision: 10, scale: 2
    t.integer "target_profit_percent", default: 25
    t.string "status", default: "idle", null: false
    t.decimal "last_sale_profit", precision: 10, scale: 2
    t.integer "last_sale_day"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "location_id"], name: "index_buddies_on_game_id_and_location_id"
    t.index ["game_id", "status"], name: "index_buddies_on_game_id_and_status"
    t.index ["game_id"], name: "index_buddies_on_game_id"
    t.index ["location_id"], name: "index_buddies_on_location_id"
    t.index ["resource_id"], name: "index_buddies_on_resource_id"
  end

  create_table "event_logs", force: :cascade do |t|
    t.integer "game_id", null: false
    t.string "loggable_type"
    t.integer "loggable_id"
    t.text "message", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "read_at"
    t.integer "game_day"
    t.index ["game_id", "created_at"], name: "index_event_logs_on_game_id_and_created_at"
    t.index ["game_id", "read_at"], name: "index_event_logs_on_game_id_and_read_at"
    t.index ["game_id"], name: "index_event_logs_on_game_id"
    t.index ["loggable_type", "loggable_id"], name: "index_event_logs_on_loggable"
  end

  create_table "events", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "day_start"
    t.integer "duration"
    t.boolean "active", default: false
    t.json "resource_effects"
    t.json "location_effects"
    t.string "event_type"
    t.integer "severity"
    t.string "rarity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "game_events", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "event_id", null: false
    t.integer "day_triggered"
    t.integer "days_remaining"
    t.boolean "seen", default: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id"], name: "index_game_events_on_event_id"
    t.index ["game_id"], name: "index_game_events_on_game_id"
  end

  create_table "game_resources", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "resource_id", null: false
    t.decimal "current_price", precision: 10, scale: 2, null: false
    t.decimal "base_price", precision: 10, scale: 2, null: false
    t.integer "available_quantity", default: 100, null: false
    t.decimal "price_direction", precision: 3, scale: 2, default: "0.0", null: false
    t.decimal "price_momentum", precision: 3, scale: 2, default: "0.5", null: false
    t.integer "last_refreshed_day", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "sine_phase_offset", precision: 5, scale: 4, default: "0.0", null: false
    t.decimal "trend_phase_offset", precision: 5, scale: 4, default: "0.0", null: false
    t.index ["game_id", "resource_id"], name: "index_game_resources_unique", unique: true
    t.index ["game_id"], name: "index_game_resources_on_game_id"
    t.index ["resource_id"], name: "index_game_resources_on_resource_id"
  end

  create_table "games", force: :cascade do |t|
    t.integer "current_day", default: 1, null: false
    t.integer "current_location_id"
    t.decimal "cash", precision: 10, scale: 2, default: "5000.0", null: false
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
    t.integer "active_game_event_id"
    t.string "difficulty", default: "street_peddler", null: false
    t.decimal "wealth_target", precision: 15, scale: 2, default: "25000.0", null: false
    t.integer "day_target", default: 30, null: false
    t.index ["active_game_event_id"], name: "index_games_on_active_game_event_id"
    t.index ["difficulty"], name: "index_games_on_difficulty"
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

  create_table "inventory_items", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "resource_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "purchase_price", precision: 10, scale: 2, null: false
    t.integer "purchase_day", null: false
    t.integer "purchase_location_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "resource_id"], name: "index_inventory_items_on_game_id_and_resource_id"
    t.index ["game_id"], name: "index_inventory_items_on_game_id"
    t.index ["resource_id"], name: "index_inventory_items_on_resource_id"
  end

  create_table "location_visits", force: :cascade do |t|
    t.integer "game_id", null: false
    t.integer "location_id", null: false
    t.integer "visited_on", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id", "location_id", "visited_on"], name: "index_location_visits_unique"
    t.index ["game_id", "visited_on"], name: "index_location_visits_on_game_and_day"
    t.index ["game_id"], name: "index_location_visits_on_game_id"
    t.index ["location_id"], name: "index_location_visits_on_location_id"
  end

  create_table "locations", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.integer "x", null: false
    t.integer "y", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "population", default: 0, null: false
    t.index ["x", "y"], name: "index_locations_on_x_and_y", unique: true
  end

  create_table "resource_price_histories", force: :cascade do |t|
    t.integer "game_resource_id", null: false
    t.integer "day", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "quantity", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_resource_id", "day", "price"], name: "index_price_histories_for_analysis"
    t.index ["game_resource_id", "day"], name: "index_price_histories_unique", unique: true
    t.index ["game_resource_id"], name: "index_resource_price_histories_on_game_resource_id"
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

  add_foreign_key "buddies", "games"
  add_foreign_key "buddies", "locations"
  add_foreign_key "buddies", "resources"
  add_foreign_key "event_logs", "games"
  add_foreign_key "game_events", "events"
  add_foreign_key "game_events", "games"
  add_foreign_key "game_resources", "games"
  add_foreign_key "game_resources", "resources"
  add_foreign_key "games", "game_events", column: "active_game_event_id"
  add_foreign_key "inventory_items", "games"
  add_foreign_key "inventory_items", "resources"
  add_foreign_key "location_visits", "games"
  add_foreign_key "location_visits", "locations"
  add_foreign_key "resource_price_histories", "game_resources"
end
