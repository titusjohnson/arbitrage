# Handles game state changes that occur during a turn
# This action updates market prices and inventory across all locations
#
# Usage:
#   action = GameTurnAction.new(game)
#   action.run
#
# This action:
#   - Updates all LocationResource prices based on market forces
#   - Adjusts available quantities based on supply/demand
#   - Creates parabolic price movements over time
#
# Note: This action does NOT validate game_must_be_continuable since it's
# called during travel and other actions that already validate this.
class GameTurnAction < GameAction
  # Override the continuable validation since this is an internal action
  # that runs as part of other validated actions
  validate :game_must_be_continuable, if: -> { false }

  def initialize(game)
    super(game, {})
  end

  def run
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Update all location resources for this game
      game.location_resources.find_each do |location_resource|
        location_resource.update_market_dynamics!(game.current_day)
      end
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to update market: #{e.message}")
    false
  end
end
