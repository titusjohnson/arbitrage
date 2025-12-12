# == Schema Information
#
# Table name: resources
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  description      :text
#  base_price_min   :decimal(10, 2)   not null
#  base_price_max   :decimal(10, 2)   not null
#  price_volatility :decimal(5, 2)    default(50.0), not null
#  inventory_size   :integer          default(1), not null
#  rarity           :string           default("common"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_resources_on_name    (name) UNIQUE
#  index_resources_on_rarity  (rarity)
#
FactoryBot.define do
  factory :resource do
    sequence(:name) { |n| "Resource #{n}" }
    description { "A valuable tradeable commodity" }
    base_price_min { 100.00 }
    base_price_max { 500.00 }
    price_volatility { 50.00 }
    inventory_size { 1 }

    # Tags can be set using tag_names attribute
    # Example: create(:resource, tag_names: ["tradeable", "common"])
    transient do
      tag_names { [] }
    end

    after(:create) do |resource, evaluator|
      if evaluator.tag_names.any?
        resource.tag_names = evaluator.tag_names
        resource.save
      end
    end

    trait :electronics do
      name { "Electronics" }
      description { "Consumer electronics and gadgets" }
      base_price_min { 200.00 }
      base_price_max { 1000.00 }
      price_volatility { 60.00 }
      inventory_size { 2 }
    end

    trait :luxury_goods do
      name { "Luxury Goods" }
      description { "High-end fashion and accessories" }
      base_price_min { 500.00 }
      base_price_max { 2000.00 }
      price_volatility { 70.00 }
      inventory_size { 1 }
    end

    trait :raw_materials do
      name { "Raw Materials" }
      description { "Industrial metals and minerals" }
      base_price_min { 50.00 }
      base_price_max { 200.00 }
      price_volatility { 40.00 }
      inventory_size { 5 }
    end

    trait :food_produce do
      name { "Food & Produce" }
      description { "Fresh food and agricultural products" }
      base_price_min { 20.00 }
      base_price_max { 100.00 }
      price_volatility { 80.00 }
      inventory_size { 3 }
    end

    trait :textiles do
      name { "Textiles" }
      description { "Fine fabrics and clothing materials" }
      base_price_min { 75.00 }
      base_price_max { 300.00 }
      price_volatility { 50.00 }
      inventory_size { 2 }
    end

    trait :collectibles do
      name { "Collectibles" }
      description { "Rare items and memorabilia" }
      base_price_min { 1000.00 }
      base_price_max { 5000.00 }
      price_volatility { 90.00 }
      inventory_size { 1 }
    end

    trait :precious_metals do
      name { "Precious Metals" }
      description { "Gold, silver, and platinum" }
      base_price_min { 800.00 }
      base_price_max { 3000.00 }
      price_volatility { 35.00 }
      inventory_size { 1 }
    end

    trait :high_volatility do
      price_volatility { 85.00 }
    end

    trait :low_volatility do
      price_volatility { 15.00 }
    end

    trait :bulky do
      inventory_size { 10 }
    end

    trait :compact do
      inventory_size { 1 }
    end
  end
end
