# Handles game state changes that occur during a turn
# This action updates market prices and inventory game-wide
#
# Usage:
#   action = GameTurnAction.new(game)
#   action.run
#
# This action:
#   - Updates all GameResource prices based on market forces
#   - Adjusts available quantities based on supply/demand
#   - Creates parabolic price movements over time
#   - Triggers random events (20% chance)
#   - Decrements active event duration
#
# Note: This action does NOT validate game_must_be_continuable since it's
# called during travel and other actions that already validate this.
class GameTurnAction < GameAction
  # Override the continuable validation since this is an internal action
  # that runs as part of other validated actions
  validate :game_must_be_continuable, if: -> { false }

  EVENT_TRIGGER_CHANCE = 0.20 # 20% chance to trigger an event each turn

  def initialize(game)
    super(game, {})
  end

  def run
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Update all game resources for this game
      game.game_resources.find_each do |game_resource|
        game_resource.update_market_dynamics!(game.current_day)
      end

      # Decrement active event duration if one exists
      decrement_active_event_duration

      # Trigger a new event (20% chance) if no active event
      trigger_random_event if should_trigger_event?

      # Check if any buddies should auto-sell
      process_buddy_sales
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to update market: #{e.message}")
    false
  end

  private

  def should_trigger_event?
    # Allow multiple concurrent events
    rand < EVENT_TRIGGER_CHANCE
  end

  def trigger_random_event
    # Select a random event using weighted probabilities
    event = Event.random_weighted
    return unless event

    # Create a GameEvent instance for this game
    game.game_events.create!(
      event: event,
      day_triggered: game.current_day,
      days_remaining: event.duration || 1,
      seen: false
    )
  end

  def decrement_active_event_duration
    # Get all currently active game events
    active_events = game.game_events.active

    active_events.each do |game_event|
      # Decrement the days remaining
      game_event.decrement_days!
    end
  end

  def process_buddy_sales
    service = BuddyCheckService.new(game)
    sales = service.call

    sales.each do |sale|
      buddy = sale[:buddy]
      resource = sale[:resource]
      profit = sale[:profit]

      game.event_logs.create!(
        message: "#{buddy.name} sold #{sale[:quantity]}x #{resource.name} for $#{profit.round(2)} profit at #{buddy.location.name}!",
        loggable: buddy
      )
    end
  end
end
