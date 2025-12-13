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
#  game_id      (games.id)
#  location_id  (locations.id)
#
class LocationVisit < ApplicationRecord
  belongs_to :game
  belongs_to :location

  validates :visited_on, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 30
  }

  scope :recent, ->(days = 10) { where('visited_on >= ?', days).order(visited_on: :desc) }
  scope :for_game, ->(game) { where(game: game) }
end
