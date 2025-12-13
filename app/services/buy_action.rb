# Handles purchasing resources
#
# Usage:
#   action = BuyAction.new(game, resource_id: 5, quantity: 10, price_per_unit: 15.50, location_resource_id: 123)
#   if action.valid?
#     success = action.run # returns true/false
#   else
#     action.errors.full_messages
#   end
#
# Params:
#   - resource_id: ID of the resource to purchase (required)
#   - quantity: Number of units to purchase (required, must be positive integer)
#   - price_per_unit: Current market price per unit (required, must be positive)
#   - location_resource_id: ID of the LocationResource to decrement (required)
#
# Validations:
#   - Resource must exist
#   - Quantity must be positive
#   - Price must be positive
#   - Player must have enough cash
#   - Player must have enough inventory space
#   - Must have enough available quantity at location
#
class BuyAction < GameAction
  attribute :resource_id, :integer
  attribute :quantity, :integer
  attribute :price_per_unit, :decimal
  attribute :location_resource_id, :integer

  validates :resource_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_per_unit, presence: true, numericality: { greater_than: 0 }
  validates :location_resource_id, presence: true

  validate :resource_must_exist
  validate :location_resource_must_exist
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

      # Decrement the available quantity at the location
      location_resource.decrement!(:available_quantity, quantity)

      create_log(resource, "Purchased #{quantity} of #{resource.name}")
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
    false
  end

  private

  def resource
    @resource ||= Resource.find_by(id: resource_id)
  end

  def location_resource
    @location_resource ||= LocationResource.find_by(id: location_resource_id)
  end

  def total_cost
    return 0 if price_per_unit.nil? || quantity.nil?
    (price_per_unit * quantity).round(2)
  end

  def resource_must_exist
    return if resource_id.nil?

    if resource.nil?
      errors.add(:resource_id, "does not exist")
    end
  end

  def location_resource_must_exist
    return if location_resource_id.nil?

    if location_resource.nil?
      errors.add(:location_resource_id, "does not exist")
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
    return if location_resource.nil? || quantity.nil?

    if location_resource.available_quantity < quantity
      errors.add(:quantity, "insufficient stock (need #{quantity}, available #{location_resource.available_quantity})")
    end
  end
end
