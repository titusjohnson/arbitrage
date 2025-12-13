# == Schema Information
#
# Table name: locations
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  population  :integer          default(0), not null
#  x           :integer          not null
#  y           :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_locations_on_x_and_y  (x,y) UNIQUE
#
class Location < ApplicationRecord
  # Tagging
  Gutentag::ActiveRecord.call self

  # Associations
  has_many :location_resources, dependent: :destroy
  has_many :location_visits, dependent: :destroy

  # Validations
  validates :name, presence: true
  validates :x, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 5 }
  validates :y, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0, less_than_or_equal_to: 4 }
  validates :x, uniqueness: { scope: :y, message: "and y coordinates must be unique" }
  validates :population, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  # Scopes
  scope :at_coordinates, ->(x, y) { find_by(x: x, y: y) }

  # Calculate distance between two locations (Manhattan distance)
  def distance_to(other_location)
    (x - other_location.x).abs + (y - other_location.y).abs
  end

  # Get coordinates as a tuple
  def coordinates
    [x, y]
  end

  # Find neighboring locations (up, down, left, right)
  def neighbors
    Location.where(
      "(x = ? AND y IN (?)) OR (y = ? AND x IN (?))",
      x, [y - 1, y + 1],
      y, [x - 1, x + 1]
    )
  end
end
