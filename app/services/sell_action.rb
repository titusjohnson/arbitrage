# Handles selling resources
#
# Usage:
#   action = SellAction.new(game, resource_id: 5, quantity: 10, price_per_unit: 20.00)
#   if action.valid?
#     result = action.run
#     # result is a hash with: { success: true, resource: Resource, quantity: 10, total_revenue: 200.00, profit: 50.00 }
#   else
#     action.errors.full_messages
#   end
#
# Params:
#   - resource_id: ID of the resource to sell (required)
#   - quantity: Number of units to sell (required, must be positive integer)
#   - price_per_unit: Current market price per unit (required, must be positive)
#
# Validations:
#   - Resource must exist
#   - Quantity must be positive
#   - Price must be positive
#   - Player must own enough of the resource
#
class SellAction < GameAction
  attribute :resource_id, :integer
  attribute :quantity, :integer
  attribute :price_per_unit, :decimal

  validates :resource_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price_per_unit, presence: true, numericality: { greater_than: 0 }

  validate :resource_must_exist
  validate :must_own_enough_resources

  def run
    raise "Cannot run invalid action" unless valid?

    result = {
      success: false,
      resource: nil,
      quantity: 0,
      total_revenue: 0,
      profit: 0
    }

    total_revenue = (price_per_unit * quantity).round(2)

    # Calculate profit before selling (need to check purchase prices)
    profit = calculate_profit

    # Use the existing game method which handles the transaction
    if game.sell_resource(resource, quantity, price_per_unit)
      result[:success] = true
      result[:resource] = resource
      result[:quantity] = quantity
      result[:total_revenue] = total_revenue
      result[:profit] = profit

      # Update best deal if this is a new record
      if profit > game.best_deal_profit
        game.update!(best_deal_profit: profit)
      end
    else
      errors.add(:base, "Failed to complete sale")
    end

    result
  end

  private

  def resource
    @resource ||= Resource.find_by(id: resource_id)
  end

  def total_revenue
    return 0 if price_per_unit.nil? || quantity.nil?
    (price_per_unit * quantity).round(2)
  end

  def resource_must_exist
    return if resource_id.nil?

    if resource.nil?
      errors.add(:resource_id, "does not exist")
    end
  end

  def must_own_enough_resources
    return if game.nil? || resource.nil? || quantity.nil?

    owned_quantity = game.inventory_items.where(resource: resource).sum(:quantity)

    if owned_quantity < quantity
      errors.add(:inventory, "not enough #{resource.name} (need #{quantity}, have #{owned_quantity})")
    end
  end

  def calculate_profit
    return 0 if game.nil? || resource.nil? || quantity.nil?

    total_revenue = (price_per_unit * quantity).round(2)
    total_cost = 0
    remaining = quantity

    # Calculate cost using FIFO (same as game.sell_resource does)
    game.inventory_items.where(resource: resource).fifo.each do |item|
      break if remaining <= 0

      quantity_from_stack = [item.quantity, remaining].min
      total_cost += (quantity_from_stack * item.purchase_price).round(2)
      remaining -= quantity_from_stack
    end

    (total_revenue - total_cost).round(2)
  end
end
