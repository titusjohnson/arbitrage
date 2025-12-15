class CollectBuddySaleAction < GameAction
  attribute :buddy_id, :integer

  validates :buddy_id, presence: true

  validate :buddy_must_exist
  validate :buddy_has_sale
  validate :buddy_at_current_location

  attr_reader :total_collected

  def run
    buddy = game.buddies.find(buddy_id)
    @total_collected = buddy.collect_proceeds!

    create_log(buddy, "Collected $#{@total_collected.round(2)} from #{buddy.name}")

    true
  end

  private

  def buddy_must_exist
    return unless buddy_id

    unless game.buddies.exists?(buddy_id)
      errors.add(:base, "Buddy not found")
    end
  end

  def buddy_has_sale
    return unless buddy_id

    buddy = game.buddies.find_by(id: buddy_id)
    return unless buddy

    unless buddy.sold?
      errors.add(:base, "#{buddy.name} has no sale to collect")
    end
  end

  def buddy_at_current_location
    return unless buddy_id

    buddy = game.buddies.find_by(id: buddy_id)
    return unless buddy

    unless buddy.location_id == game.current_location_id
      errors.add(:base, "You must be at #{buddy.location.name} to collect from #{buddy.name}")
    end
  end
end
