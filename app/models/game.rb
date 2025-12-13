# == Schema Information
#
# Table name: games
#
#  id                 :integer          not null, primary key
#  current_day        :integer          default(1), not null
#  current_location_id:integer
#  cash               :decimal(10, 2)   default(2000.0), not null
#  bank_balance       :decimal(10, 2)   default(0.0), not null
#  debt               :decimal(10, 2)   default(0.0), not null
#  status             :string           default("active"), not null
#  final_score        :integer
#  health             :integer          default(10), not null
#  max_health         :integer          default(10), not null
#  inventory_capacity :integer          default(100), not null
#  started_at         :datetime         not null
#  completed_at       :datetime
#  total_purchases    :integer          default(0), not null
#  total_sales        :integer          default(0), not null
#  locations_visited  :integer          default(1), not null
#  best_deal_profit   :decimal(10, 2)   default(0.0), not null
#  restore_key        :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_games_on_restore_key  (restore_key) UNIQUE
#  index_games_on_started_at   (started_at)
#  index_games_on_status       (status)
#
class Game < ApplicationRecord
  # Associations
  belongs_to :current_location, class_name: 'Location'
  has_many :game_events, dependent: :destroy
  has_many :events, through: :game_events
  has_many :inventory_items, dependent: :destroy
  has_many :resources, through: :inventory_items

  # Validations
  validates :restore_key, presence: true, uniqueness: true

  validates :current_day, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1,
    less_than_or_equal_to: 30
  }

  validates :cash, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :bank_balance, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :debt, presence: true, numericality: { greater_than_or_equal_to: 0 }

  validates :status, presence: true, inclusion: { in: %w[active completed game_over] }

  validates :health, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: :max_health
  }

  validates :max_health, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1
  }

  validates :inventory_capacity, presence: true, numericality: {
    only_integer: true,
    greater_than_or_equal_to: 1
  }

  validates :started_at, presence: true

  # Callbacks
  before_validation :set_restore_key, on: :create
  before_validation :set_started_at, on: :create
  before_validation :set_starting_location, on: :create

  # Scopes
  scope :active, -> { where(status: "active") }
  scope :completed, -> { where(status: "completed") }
  scope :game_over, -> { where(status: "game_over") }
  scope :finished, -> { where(status: [ "completed", "game_over" ]) }
  scope :recent, -> { order(started_at: :desc) }

  # Instance Methods

  def total_cash
    cash + bank_balance - debt
  end

  def net_worth
    total_cash + inventory_value
  end

  def days_remaining
    30 - current_day
  end

  def game_over?
    status == "game_over"
  end

  def completed?
    status == "completed"
  end

  def active?
    status == "active"
  end

  def finished?
    completed? || game_over?
  end

  def can_continue?
    active? && current_day <= 30 && health > 0
  end

  def advance_day!
    return false unless can_continue?

    increment!(:current_day)

    # Check if game should end
    if current_day >= 30
      complete_game!
    end

    true
  end

  def complete_game!
    return if finished?

    self.status = "completed"
    self.completed_at = Time.current
    self.final_score = calculate_final_score
    save!
  end

  def end_game!
    return if finished?

    self.status = "game_over"
    self.completed_at = Time.current
    self.final_score = calculate_final_score
    save!
  end

  def calculate_final_score
    # Score formula: (net worth in millions × 2) capped at 100
    score = (net_worth / 1_000_000.0 * 2).to_i
    [ score, 100 ].min
  end

  # Inventory Management

  def current_inventory_size
    inventory_items.joins(:resource).sum('resources.inventory_size * inventory_items.quantity')
  end

  def available_inventory_space
    inventory_capacity - current_inventory_size
  end

  def can_add_to_inventory?(resource, quantity = 1)
    required_space = resource.inventory_size * quantity
    available_inventory_space >= required_space
  end

  def inventory_value
    inventory_items.sum { |item| item.quantity * item.purchase_price }
  end

  def buy_resource(resource, quantity, price_per_unit, location = nil)
    return false unless can_purchase?(resource, quantity, price_per_unit)

    total_cost = (price_per_unit * quantity).round(2)

    ActiveRecord::Base.transaction do
      # Deduct cash
      update!(cash: cash - total_cost)

      # Add to inventory (stack if same resource/price exists, otherwise create new)
      item = inventory_items.find_or_initialize_by(
        resource: resource,
        purchase_price: price_per_unit
      )

      if item.new_record?
        item.assign_attributes(
          quantity: quantity,
          purchase_day: current_day,
          purchase_location_id: location&.id
        )
        item.save!
      else
        item.increment!(:quantity, quantity)
      end

      increment!(:total_purchases, quantity)
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved => e
    Rails.logger.error("Failed to purchase resource: #{e.message}")
    false
  end

  def can_purchase?(resource, quantity, price_per_unit)
    total_cost = (price_per_unit * quantity).round(2)
    return false if cash < total_cost
    return false unless can_add_to_inventory?(resource, quantity)
    true
  end

  def sell_resource(resource, quantity, price_per_unit)
    return false unless can_sell?(resource, quantity)

    total_revenue = (price_per_unit * quantity).round(2)
    remaining_to_sell = quantity

    ActiveRecord::Base.transaction do
      # Get inventory items for this resource in FIFO order (oldest first)
      items_to_sell = inventory_items.where(resource: resource).fifo

      items_to_sell.each do |item|
        break if remaining_to_sell <= 0

        if item.quantity <= remaining_to_sell
          # Sell entire stack
          remaining_to_sell -= item.quantity
          item.destroy!
        else
          # Sell partial stack
          item.decrement!(:quantity, remaining_to_sell)
          remaining_to_sell = 0
        end
      end

      # Add cash
      update!(cash: cash + total_revenue)

      # Update statistics
      increment!(:total_sales, quantity)
    end

    true
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotDestroyed => e
    Rails.logger.error("Failed to sell resource: #{e.message}")
    false
  end

  def can_sell?(resource, quantity)
    total_available = inventory_items.where(resource: resource).sum(:quantity)
    total_available >= quantity
  end

  private

  def set_restore_key
    self.restore_key ||= SecureRandom.urlsafe_base64(32)
  end

  def set_started_at
    self.started_at ||= Time.current
  end

  def set_starting_location
    self.current_location ||= Location.order("RANDOM()").first
  end
end
