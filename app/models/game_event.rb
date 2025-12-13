# == Schema Information
#
# Table name: game_events
#
#  id             :integer          not null, primary key
#  day_triggered  :integer
#  days_remaining :integer
#  seen           :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  event_id       :integer          not null
#  game_id        :integer          not null
#
# Indexes
#
#  index_game_events_on_event_id  (event_id)
#  index_game_events_on_game_id   (game_id)
#
# Foreign Keys
#
#  event_id  (event_id => events.id)
#  game_id   (game_id => games.id)
#
class GameEvent < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :event

  # Validations
  validates :day_triggered, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 30 }, allow_nil: true
  validates :days_remaining, numericality: { only_integer: true, greater_than_or_equal_to: 0 }, allow_nil: true

  # Scopes
  scope :active, -> { where("days_remaining > ?", 0) }
  scope :expired, -> { where(days_remaining: 0) }
  scope :unseen, -> { where(seen: false) }

  # Instance methods
  def active?
    return false if days_remaining.nil?

    days_remaining > 0
  end

  def expired?
    return false if days_remaining.nil?

    days_remaining <= 0
  end

  def decrement_days!
    return unless days_remaining && days_remaining > 0

    update(days_remaining: days_remaining - 1)
  end
end
