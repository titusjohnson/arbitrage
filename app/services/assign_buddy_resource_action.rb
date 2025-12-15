class AssignBuddyResourceAction < GameAction
  attribute :buddy_id, :integer
  attribute :resource_id, :integer
  attribute :quantity, :integer
  attribute :target_profit_percent, :integer, default: 25

  validates :buddy_id, :resource_id, :quantity, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :target_profit_percent, numericality: { greater_than: 0, less_than_or_equal_to: 200 }

  validate :buddy_must_exist
  validate :buddy_must_be_idle
  validate :buddy_must_be_at_current_location
  validate :resource_must_exist
  validate :player_has_inventory

  def run
    buddy = game.buddies.find(buddy_id)
    resource = Resource.find(resource_id)

    # Calculate weighted average purchase price from inventory
    avg_price = calculate_average_price(resource)

    # Remove from player inventory (FIFO)
    deduct_from_inventory(resource, quantity)

    # Assign to buddy
    buddy.update!(
      resource: resource,
      quantity: quantity,
      purchase_price: avg_price,
      target_profit_percent: target_profit_percent,
      status: 'holding'
    )

    create_log(buddy, "Gave #{quantity}x #{resource.name} to #{buddy.name} (sell at +#{target_profit_percent}%)")

    true
  end

  private

  def buddy_must_exist
    return unless buddy_id

    unless game.buddies.exists?(buddy_id)
      errors.add(:base, "Buddy not found")
    end
  end

  def buddy_must_be_idle
    return unless buddy_id

    buddy = game.buddies.find_by(id: buddy_id)
    return unless buddy

    unless buddy.idle?
      errors.add(:base, "#{buddy.name} is already holding resources")
    end
  end

  def buddy_must_be_at_current_location
    return unless buddy_id

    buddy = game.buddies.find_by(id: buddy_id)
    return unless buddy

    unless buddy.location_id == game.current_location_id
      errors.add(:base, "#{buddy.name} is not at your current location")
    end
  end

  def resource_must_exist
    return unless resource_id

    unless Resource.exists?(resource_id)
      errors.add(:resource_id, "Resource not found")
    end
  end

  def player_has_inventory
    return unless resource_id && quantity

    resource = Resource.find_by(id: resource_id)
    return unless resource

    total = game.inventory_items.by_resource(resource).sum(:quantity)
    if total < quantity
      errors.add(:base, "Not enough #{resource.name} in inventory (have #{total})")
    end
  end

  def calculate_average_price(resource)
    items = game.inventory_items.by_resource(resource)
    total_value = items.sum { |i| i.quantity * i.purchase_price }
    total_qty = items.sum(&:quantity)
    (total_value / total_qty).round(2)
  end

  def deduct_from_inventory(resource, qty_to_remove)
    remaining = qty_to_remove

    game.inventory_items.by_resource(resource).fifo.each do |item|
      break if remaining <= 0

      if item.quantity <= remaining
        remaining -= item.quantity
        item.destroy!
      else
        item.update!(quantity: item.quantity - remaining)
        remaining = 0
      end
    end
  end
end
