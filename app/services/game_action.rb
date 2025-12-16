# Base class for all game actions
# Provides validation and error handling similar to ActiveRecord models
#
# Usage:
#   action = TravelAction.new(game, destination_id: 5)
#   if action.valid?
#     action.run
#   else
#     action.errors # => ActiveModel::Errors object
#   end
class GameAction
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations

  attr_reader :game, :log

  # Validations that apply to all actions
  validates :game, presence: true
  validate :game_must_be_active
  validate :game_must_be_continuable

  def initialize(game, params = {})
    @game = game
    super(params)
  end

  # Subclasses must implement this method
  def run
    raise NotImplementedError, "#{self.class} must implement #run"
  end

  # Convenience method to validate and run in one call
  # Returns true if successful, false if validation failed
  def call
    return false unless valid?

    run
  end

  protected

  # Helper to create an event log for this action
  # @param loggable [ActiveRecord::Base, nil] Optional related object (Resource, Location, etc.)
  # @param message [String] Log message to record
  # @return [EventLog] The created log record
  def create_log(loggable, message)
    @log = game.event_logs.create!(
      message: message,
      loggable: loggable,
      game_day: game.current_day
    )
  end

  # Helper to add game-level errors
  def add_game_error(message)
    errors.add(:base, message)
  end

  # Helper to check if game can continue
  def game_can_continue?
    game&.can_continue?
  end

  # Helper to check if game is active
  def game_active?
    game&.active?
  end

  private

  def game_must_be_active
    return if game.nil? # presence validation will catch this

    unless game_active?
      errors.add(:base, "Game is not active")
    end
  end

  def game_must_be_continuable
    return if game.nil? # presence validation will catch this

    unless game_can_continue?
      if game.health <= 0
        errors.add(:base, "Game over: no health remaining")
      elsif game.current_day > game.day_target
        errors.add(:base, "Game over: all days completed")
      else
        errors.add(:base, "Cannot continue game")
      end
    end
  end
end
