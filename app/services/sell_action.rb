# Handles selling resources
#
# Usage:
#   action = SellAction.new(game, location_resource_id: 123, quantity: 10)
#   if action.run
#     # Sale successful
#   else
#     action.errors.full_messages
#   end
#
# Params:
#   - location_resource_id: ID of the LocationResource (required)
#   - quantity: Number of units to sell (required, must be positive integer)
#
# Validations:
#   - LocationResource must exist
#   - Quantity must be positive
#   - Player must own enough of the resource
#
class SellAction < GameAction
  attribute :location_resource_id, :integer
  attribute :quantity, :integer

  validates :location_resource_id, presence: true
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validate :location_resource_must_exist
  validate :must_own_enough_resources

  def run
    return false unless valid?

    ActiveRecord::Base.transaction do
      total_revenue = (price_per_unit * quantity).round(2)

      # Calculate profit before selling (need to check purchase prices)
      profit = calculate_profit

      # Use the existing game method which handles the transaction
      unless game.sell_resource(resource, quantity, price_per_unit)
        errors.add(:base, "Failed to complete sale")
        raise ActiveRecord::Rollback
      end

      # Update best deal if this is a new record
      if profit > game.best_deal_profit
        game.update!(best_deal_profit: profit)
      end

      # Log the sale
      create_log(resource, "Sold #{quantity} #{resource.name.pluralize(quantity)} for $#{total_revenue} (profit: $#{profit}).")
    end

    true
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, "Failed to save game: #{e.message}")
    false
  end

  private

  def location_resource
    @location_resource ||= LocationResource.find_by(id: location_resource_id)
  end

  def resource
    @resource ||= location_resource&.resource
  end

  def price_per_unit
    @price_per_unit ||= location_resource&.current_price
  end

  def total_revenue
    return 0 if price_per_unit.nil? || quantity.nil?
    (price_per_unit * quantity).round(2)
  end

  def location_resource_must_exist
    return if location_resource_id.nil?

    if location_resource.nil?
      errors.add(:location_resource_id, "does not exist")
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
