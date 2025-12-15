# Handles purchasing resources
#
# Usage:
#   action = BuyAction.new(game, game_resource_id: 123, quantity: 10)
#   if action.valid?
#     success = action.run # returns true/false
#   else
#     action.errors.full_messages
#   end
#
# Params:
#   - game_resource_id: ID of the GameResource (required)
#   - quantity: Number of units to purchase (required, must be positive integer)
#
# Validations:
#   - GameResource must exist
#   - Quantity must be positive
#   - Player must have enough cash
#   - Player must have enough inventory space
#   - Must have enough available quantity
#
class BuyAction < GameAction
  attribute :game_resource_id, :integer
  attribute :quantity, :integer

  validates :game_resource_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validate :game_resource_must_exist
  validate :must_have_enough_cash
  validate :must_have_inventory_space
  validate :must_have_enough_available_quantity

  def run
    return false unless valid?

    ActiveRecord::Base.transaction do
      # Use the existing game method which handles the transaction
      success = game.buy_resource(resource, quantity, price_per_unit, game.current_location)

      unless success
        errors.add(:base, "Failed to complete purchase")
        raise ActiveRecord::Rollback
      end

      # Decrement the available quantity
      game_resource.decrement!(:available_quantity, quantity)

      # Check for event effects (with current location for location bonuses)
      event_effects = EventEffectsService.new(game, game_resource, location: game.current_location).call
      has_event_effects = event_effects[:price_multiplier] != 1.0

      # Create log message
      log_message = "Purchased #{quantity} #{resource.name.pluralize(quantity)} for $#{total_cost}"
      if has_event_effects
        multiplier_pct = ((event_effects[:price_multiplier] - 1.0) * 100).round(0)
        if event_effects[:price_multiplier] > 1.0
          log_message += " (⚡ +#{multiplier_pct}% event price)"
        else
          log_message += " (⚡ #{multiplier_pct}% event price)"
        end
      end
      log_message += "."

      create_log(resource, log_message)
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
    false
  end

  private

  def game_resource
    @game_resource ||= GameResource.find_by(id: game_resource_id)
  end

  def resource
    @resource ||= game_resource&.resource
  end

  def price_per_unit
    return nil unless game_resource
    @price_per_unit ||= game_resource.price_at_location(game.current_location)
  end

  def total_cost
    return 0 if price_per_unit.nil? || quantity.nil?
    (price_per_unit * quantity).round(2)
  end

  def game_resource_must_exist
    return if game_resource_id.nil?

    if game_resource.nil?
      errors.add(:game_resource_id, "does not exist")
    end
  end

  def must_have_enough_cash
    return if game.nil? || price_per_unit.nil? || quantity.nil?

    if game.cash < total_cost
      errors.add(:cash, "insufficient funds (need #{total_cost}, have #{game.cash})")
    end
  end

  def must_have_inventory_space
    return if game.nil? || resource.nil? || quantity.nil?

    unless game.can_add_to_inventory?(resource, quantity)
      required_space = resource.inventory_size * quantity
      available_space = game.available_inventory_space

      errors.add(:inventory, "insufficient space (need #{required_space}, have #{available_space})")
    end
  end

  def must_have_enough_available_quantity
    return if game_resource.nil? || quantity.nil?

    if game_resource.available_quantity < quantity
      errors.add(:quantity, "insufficient stock (need #{quantity}, available #{game_resource.available_quantity})")
    end
  end
end
