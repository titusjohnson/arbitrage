# == Schema Information
#
# Table name: game_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  base_price         :decimal(10, 2)   not null
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  price_direction    :decimal(3, 2)    default(0.0), not null
#  price_momentum     :decimal(3, 2)    default(0.5), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_game_resources_unique  (game_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  resource_id  (resource_id => resources.id)
#
FactoryBot.define do
  factory :game_resource do
    association :game
    association :resource
    current_price { resource&.generate_market_price || 100.00 }
    base_price { current_price }
    available_quantity { 100 }
    last_refreshed_day { game&.current_day || 1 }
    price_direction { 0.0 }
    price_momentum { 0.5 }

    trait :with_history do
      after(:create) do |game_resource|
        game_resource.generate_initial_history(days: 30)
      end
    end
  end
end
