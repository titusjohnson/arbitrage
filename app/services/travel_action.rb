# Handles player travel between locations
#
# Usage:
#   action = TravelAction.new(game, destination_id: 5)
#   if action.valid?
#     result = action.run
#     # result is a hash with: { success: true, location: Location, health_cost: 1, day_advanced: true }
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
#   - Player must have enough health for the journey
#   - Destination must be reachable (adjacent locations only for now)
#
class TravelAction < GameAction
  attribute :destination_id, :integer

  validates :destination_id, presence: true
  validate :destination_must_exist
  validate :destination_must_be_different
  validate :destination_must_be_reachable
  validate :must_have_enough_health

  def run
    raise "Cannot run invalid action" unless valid?

    result = {
      success: false,
      location: nil,
      health_cost: 0,
      day_advanced: false,
      events_triggered: []
    }

    ActiveRecord::Base.transaction do
      # Calculate health cost based on distance
      health_cost = calculate_health_cost

      # Update game state
      game.current_location_id = destination_id
      game.health -= health_cost
      game.locations_visited += 1

      # Advance the day
      day_advanced = game.advance_day!

      # Check if game ended due to health loss
      if game.health <= 0
        game.end_game!
      end

      game.save!

      # TODO: Trigger any location-based events or random encounters
      # events_triggered = trigger_travel_events

      result[:success] = true
      result[:location] = destination
      result[:health_cost] = health_cost
      result[:day_advanced] = day_advanced
    end

    result
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to save game: #{e.message}")
    result[:success] = false
    result
  end

  private

  def destination
    @destination ||= Location.find_by(id: destination_id)
  end

  def current_location
    @current_location ||= game.current_location_id ? Location.find_by(id: game.current_location_id) : nil
  end

  def calculate_health_cost
    return 1 unless current_location && destination

    # Base cost is 1 health per unit of distance
    distance = current_location.distance_to(destination)
    [distance, 1].max # Minimum 1 health even for adjacent moves
  end

  def destination_must_exist
    return if destination_id.nil? # presence validation will catch this

    if destination.nil?
      errors.add(:destination_id, "does not exist")
    end
  end

  def destination_must_be_different
    return if destination.nil? || current_location.nil?

    if destination.id == current_location.id
      errors.add(:destination_id, "must be different from current location")
    end
  end

  def destination_must_be_reachable
    return if destination.nil? || current_location.nil?

    # For now, only allow travel to adjacent locations (Manhattan distance of 1)
    # You can make this more flexible later (allow any location with higher health cost, etc.)
    distance = current_location.distance_to(destination)

    if distance > 1
      errors.add(:destination_id, "is too far away (must be adjacent)")
    end
  end

  def must_have_enough_health
    return if destination.nil? || current_location.nil?
    return if game.nil?

    health_cost = calculate_health_cost

    if game.health < health_cost
      errors.add(:base, "Not enough health for this journey (need #{health_cost}, have #{game.health})")
    end
  end
end
