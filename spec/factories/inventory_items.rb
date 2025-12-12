# == Schema Information
#
# Table name: inventory_items
#
#  id                   :integer          not null, primary key
#  game_id              :integer          not null
#  resource_id          :integer          not null
#  quantity             :integer          default(1), not null
#  purchase_price       :decimal(10, 2)   not null
#  purchase_day         :integer          not null
#  purchase_location_id :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_inventory_items_on_game_id                  (game_id)
#  index_inventory_items_on_game_id_and_resource_id  (game_id,resource_id)
#  index_inventory_items_on_resource_id              (resource_id)
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  resource_id  (resource_id => resources.id)
#
FactoryBot.define do
  factory :inventory_item do
    association :game
    association :resource
    quantity { rand(1..10) }
    purchase_price { rand(10.0..1000.0).round(2) }
    purchase_day { rand(1..30) }
    purchase_location_id { nil }

    trait :with_location do
      association :purchase_location, factory: :location
    end

    trait :large_quantity do
      quantity { rand(50..100) }
    end

    trait :expensive do
      purchase_price { rand(5000.0..10000.0).round(2) }
    end

    trait :cheap do
      purchase_price { rand(1.0..50.0).round(2) }
    end

    trait :recently_purchased do
      purchase_day { rand(25..30) }
    end

    trait :early_purchase do
      purchase_day { rand(1..5) }
    end
  end
end
