class HireBuddyAction < GameAction
  HIRE_COST = 100

  attribute :location_id, :integer

  validates :location_id, presence: true
  validate :sufficient_cash
  validate :location_exists

  attr_reader :buddy

  def run
    location = Location.find(location_id)

    @buddy = game.buddies.create!(
      location: location,
      name: Buddy.generate_name,
      hire_cost: HIRE_COST,
      hire_day: game.current_day,
      status: 'idle'
    )

    game.decrement!(:cash, HIRE_COST)

    create_log(@buddy, "Hired #{@buddy.name} at #{location.name} for $#{HIRE_COST}")

    true
  end

  private

  def sufficient_cash
    return unless game

    if game.cash < HIRE_COST
      errors.add(:base, "Not enough cash to hire a buddy (need $#{HIRE_COST})")
    end
  end

  def location_exists
    return unless location_id

    unless Location.exists?(location_id)
      errors.add(:location_id, "Location not found")
    end
  end
end
