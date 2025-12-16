# == Schema Information
#
# Table name: event_logs
#
#  id            :integer          not null, primary key
#  game_day      :integer
#  loggable_type :string
#  message       :text             not null
#  read_at       :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  game_id       :integer          not null
#  loggable_id   :integer
#
# Indexes
#
#  index_event_logs_on_game_id                 (game_id)
#  index_event_logs_on_game_id_and_created_at  (game_id,created_at)
#  index_event_logs_on_game_id_and_read_at     (game_id,read_at)
#  index_event_logs_on_loggable                (loggable_type,loggable_id)
#
# Foreign Keys
#
#  game_id  (game_id => games.id)
#
class EventLog < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :loggable, polymorphic: true, optional: true

  # Validations
  validates :message, presence: true

  # Scopes
  scope :recent, -> { order(created_at: :desc) }
  scope :for_game, ->(game) { where(game: game) }
  scope :chronological, -> { order(created_at: :asc) }
  scope :unread, -> { where(read_at: nil) }
end
