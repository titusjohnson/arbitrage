# Handles purchasing resources
#
# Usage:
#   action = BuyAction.new(game, resource_id: 5, quantity: 10, price_per_unit: 15.50)
#   if action.valid?
#     result = action.run
#     # result is a hash with: { success: true, resource: Resource, quantity: 10, total_cost: 155.00 }
#   else
#     action.errors.full_messages
#   end
#
# Params:
#   - resource_id: ID of the resource to purchase (required)
#   - quantity: Number of units to purchase (required, must be positive integer)
#   - price_per_unit: Current market price per unit (required, must be positive)
#
# Validations:
#   - Resource must exist
#   - Quantity must be positive
#   - Price must be positive
#   - Player must have enough cash
#   - Player must have enough inventory space
#
class BuyAction < GameAction
  attribute :resource_id, :integer
  attribute :quantity, :integer
  attribute :price_per_unit, :decimal

  validates :resource_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_per_unit, presence: true, numericality: { greater_than: 0 }

  validate :resource_must_exist
  validate :must_have_enough_cash
  validate :must_have_inventory_space

  def run
    raise "Cannot run invalid action" unless valid?

    result = {
      success: false,
      resource: nil,
      quantity: 0,
      total_cost: 0
    }

    total_cost = (price_per_unit * quantity).round(2)

    # Use the existing game method which handles the transaction
    if game.buy_resource(resource, quantity, price_per_unit, game.current_location)
      result[:success] = true
      result[:resource] = resource
      result[:quantity] = quantity
      result[:total_cost] = total_cost
    else
      errors.add(:base, "Failed to complete purchase")
    end

    result
  end

  private

  def resource
    @resource ||= Resource.find_by(id: resource_id)
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
end
