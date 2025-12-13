# == Schema Information
#
# Table name: location_visits
#
#  id          :integer          not null, primary key
#  visited_on  :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  game_id     :integer          not null
#  location_id :integer          not null
#
# Indexes
#
#  index_location_visits_on_game_and_day  (game_id,visited_on)
#  index_location_visits_on_game_id       (game_id)
#  index_location_visits_on_location_id   (location_id)
#  index_location_visits_unique           (game_id,location_id,visited_on)
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#
FactoryBot.define do
  factory :location_visit do
    association :game
    association :location
    visited_on { 1 }
  end
end
