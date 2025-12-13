# Handles player travel between locations
#
# Usage:
#   action = TravelAction.new(game, destination_id: 5)
#   if action.run
#     # Travel successful
#   else
#     action.errors.full_messages
#   end
#
# Params:
#   - destination_id: ID of the location to travel to (required)
#
# Validations:
#   - Destination must exist
#   - Destination must be different from current location
#   - Player must have enough cash for the journey
#   - Destination must be reachable (adjacent locations only for now)
#
class TravelAction < GameAction
  attribute :destination_id, :integer

  validates :destination_id, presence: true
  validate :destination_must_exist
  validate :destination_must_be_different
  validate :must_have_enough_cash

  def run
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Calculate travel cost based on distance
      travel_cost = calculate_travel_cost

      # Update game state
      game.current_location_id = destination_id
      game.cash -= travel_cost
      game.locations_visited += 1

      # Advance the day
      game.advance_day!

      game.save!

      # Log the travel event
      create_log(destination, "Traveled to #{destination.name} for $#{travel_cost}.")

      # Seed location resources on first visit (fog of war mechanic)
      LocationResource.seed_for_location(game, destination)

      # Update market prices and quantities across all locations
      game_turn_action = GameTurnAction.new(game)
      unless game_turn_action.run
        errors.add(:base, "Failed to update market: #{game_turn_action.errors.full_messages.join(', ')}")
        raise ActiveRecord::Rollback
      end

      # TODO: Trigger any location-based events or random encounters
      # trigger_travel_events
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to save game: #{e.message}")
    false
  end

  private

  def destination
    @destination ||= Location.find_by(id: destination_id)
  end

  def current_location
    @current_location ||= game.current_location
  end

  def calculate_travel_cost
    # Adjacent locations (distance = 1) are free (walk/drive)
    # Longer distances cost $100 per square beyond the first
    distance = current_location.distance_to(destination)
    return 0 if distance <= 1

    (distance - 1) * 100
  end

  def destination_must_exist
    return if destination_id.nil? # presence validation will catch this

    if destination.nil?
      errors.add(:destination_id, "does not exist")
    end
  end

  def destination_must_be_different
    return if destination.nil?

    if destination.id == current_location.id
      errors.add(:destination_id, "must be different from current location")
    end
  end

  def must_have_enough_cash
    return if destination.nil?

    travel_cost = calculate_travel_cost

    if game.cash < travel_cost
      errors.add(:base, "Not enough cash for this journey (need $#{travel_cost}, have $#{game.cash})")
    end
  end
end
