# == Schema Information
#
# Table name: events
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  description      :text
#  day_start        :integer
#  duration         :integer
#  active           :boolean          default(FALSE)
#  resource_effects :json
#  location_effects :json
#  event_type       :string
#  severity         :integer
#  rarity           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
class Event < ApplicationRecord
  # Constants
  RARITIES = %w[common uncommon rare ultra_rare exceptional].freeze
  EVENT_TYPES = %w[market weather political cultural].freeze
  SEVERITY_RANGE = (1..5).freeze
  DURATION_RANGE = (1..7).freeze

  # Associations
  has_many :game_events, dependent: :destroy
  has_many :games, through: :game_events

  # Validations
  validates :name, presence: true
  validates :rarity, inclusion: { in: RARITIES }
  validates :event_type, inclusion: { in: EVENT_TYPES }, allow_nil: true
  validates :severity, numericality: { only_integer: true, in: SEVERITY_RANGE }, allow_nil: true
  validates :duration, numericality: { only_integer: true, in: DURATION_RANGE }, allow_nil: true
  validates :day_start, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 30 }, allow_nil: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_rarity, ->(rarity) { where(rarity: rarity) }
  scope :by_type, ->(type) { where(event_type: type) }
end
