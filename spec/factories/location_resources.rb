# == Schema Information
#
# Table name: location_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  location_id        :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_location_resources_on_game_and_location  (game_id,location_id)
#  index_location_resources_on_game_id            (game_id)
#  index_location_resources_on_location_id        (location_id)
#  index_location_resources_on_resource_id        (resource_id)
#  index_location_resources_unique                (game_id,location_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#  resource_id  (resource_id => resources.id)
#
FactoryBot.define do
  factory :location_resource do
    association :game
    association :location
    association :resource
    current_price { resource&.generate_market_price || 100.00 }
    last_refreshed_day { game&.current_day || 1 }
  end
end
