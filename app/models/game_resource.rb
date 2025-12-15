# == Schema Information
#
# Table name: game_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  base_price         :decimal(10, 2)   not null
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  price_direction    :decimal(3, 2)    default(0.0), not null
#  price_momentum     :decimal(3, 2)    default(0.5), not null
#  sine_phase_offset  :decimal(5, 4)    default(0.0), not null
#  trend_phase_offset :decimal(5, 4)    default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_game_resources_on_game_id      (game_id)
#  index_game_resources_on_resource_id  (resource_id)
#  index_game_resources_unique          (game_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  resource_id  (resource_id => resources.id)
#
class GameResource < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :resource
  has_many :price_histories, class_name: 'ResourcePriceHistory', dependent: :destroy

  # Price dynamics constants
  # Short-term oscillation (ripples)
  SINE_PERIOD_DAYS = 10       # Full sine wave cycle in days
  SINE_AMPLITUDE = 0.10       # ±10% oscillation (20% total swing)

  # Long-term trend (waves)
  TREND_PERIOD_DAYS = 20      # Full trend cycle in days
  TREND_AMPLITUDE = 0.25      # ±25% oscillation (50% total swing)

  PRICE_FLOOR_MULTIPLIER = 0.2
  PRICE_CEILING_MULTIPLIER = 2.5

  # Validations
  validates :current_price, presence: true, numericality: { greater_than: 0 }
  validates :base_price, presence: true, numericality: { greater_than: 0 }
  validates :last_refreshed_day, presence: true, numericality: { only_integer: true }
  validates :resource_id, uniqueness: { scope: :game_id, message: "already exists for this game" }

  # Scopes
  scope :for_game, ->(game) { where(game: game) }
  scope :fresh, ->(current_day) { where("last_refreshed_day >= ?", current_day - 1) }
  scope :stale, ->(current_day) { where("last_refreshed_day < ?", current_day - 1) }

  # Seed all resources for a new game
  # Note: For new games, use HistoricalSimulationService instead which handles
  # seeding with proper historical simulation. This method is kept for backwards
  # compatibility and testing purposes.
  def self.seed_for_game(game, generate_history: true)
    return if exists?(game: game)

    transaction do
      Resource.find_each do |resource|
        price = resource.generate_market_price

        game_resource = create!(
          game: game,
          resource: resource,
          current_price: price,
          base_price: price,
          available_quantity: calculate_initial_quantity(resource, price),
          price_direction: rand(-1.0..1.0).round(2),
          price_momentum: 0.5,
          sine_phase_offset: rand(0.0..(2.0 * Math::PI)).round(4),
          trend_phase_offset: rand(0.0..(2.0 * Math::PI)).round(4),
          last_refreshed_day: game.current_day
        )

        # Generate initial price history if requested
        game_resource.generate_initial_history(days: 30) if generate_history
      end
    end
  end

  def self.calculate_initial_quantity(resource, price)
    # Based on rarity and price (no location factors)
    base_qty = case resource.rarity
               when 'exceptional' then rand(1..3)
               when 'ultra_rare'  then rand(2..5)
               when 'rare'        then rand(5..15)
               when 'uncommon'    then rand(20..40)
               else rand(50..100)
               end

    price_mod = case
                when price > 100_000 then 0.5
                when price > 10_000  then 0.7
                when price > 1_000   then 1.0
                else 1.3
                end

    [(base_qty * price_mod * rand(0.8..1.2)).round, 1].max
  end

  # Generate historical prices before game start using sinusoidal pattern
  def generate_initial_history(days: 30)
    quantity = available_quantity

    (1..days).each do |day|
      price = calculate_dynamic_price(day)
      price_histories.create!(day: day, price: price, quantity: quantity)

      # Adjust quantity inversely to price changes
      if day > 1
        prev_price = price_histories.find_by(day: day - 1)&.price || price
        price_ratio = prev_price > 0 ? (price - prev_price) / prev_price : 0
        quantity = [(quantity + (quantity * price_ratio * -0.3).round), 1].max
      end
    end
  end

  def needs_refresh?(current_day)
    last_refreshed_day < current_day
  end

  # Daily price update using layered price dynamics:
  # 1. Sinusoidal base pattern (±10% over 10-day cycle)
  # 2. Volatility-based random variation
  # 3. Supply/demand pressure
  # 4. Event modifiers (applied separately by EventEffectsService)
  def update_market_dynamics!(current_day)
    return if last_refreshed_day >= current_day

    new_price = calculate_dynamic_price(current_day)
    new_quantity = calculate_new_quantity(new_price)

    update!(
      current_price: new_price,
      available_quantity: new_quantity,
      last_refreshed_day: current_day
    )

    record_price_for_day(current_day, new_price, new_quantity)
  end

  # Calculate price using layered dynamics
  def calculate_dynamic_price(day)
    # Layer 1: Long-term trend wave (macro momentum)
    trend_modifier = calculate_trend_modifier(day)

    # Layer 2: Short-term sinusoidal pattern (ripples on top of trend)
    sine_modifier = calculate_sine_modifier(day)

    # Layer 3: Volatility-based random variation
    volatility_modifier = calculate_volatility_modifier

    # Layer 4: Supply/demand pressure
    market_pressure = calculate_supply_pressure + calculate_demand_pressure

    # Combine all modifiers (multiplicative for waves/volatility, additive for pressure)
    combined_modifier = (1.0 + trend_modifier) * (1.0 + sine_modifier) * (1.0 + volatility_modifier) + market_pressure * 0.05

    new_price = base_price * combined_modifier
    clamp_price(new_price)
  end

  # Long-term trend: ±25% over a 20-day period
  def calculate_trend_modifier(day)
    angular_frequency = 2.0 * Math::PI / TREND_PERIOD_DAYS
    Math.sin(angular_frequency * day + trend_phase_offset) * TREND_AMPLITUDE
  end

  # Short-term oscillation: ±10% over a 10-day period
  def calculate_sine_modifier(day)
    angular_frequency = 2.0 * Math::PI / SINE_PERIOD_DAYS
    Math.sin(angular_frequency * day + sine_phase_offset) * SINE_AMPLITUDE
  end

  # Random variation scaled by volatility (higher volatility = bigger swings)
  def calculate_volatility_modifier
    volatility = resource.price_volatility / 100.0
    # Base random range of ±15%, scaled by volatility
    # High volatility (100) = ±15%, Low volatility (0) = ±0%
    max_swing = 0.15 * volatility
    rand(-max_swing..max_swing)
  end

  def calculate_new_quantity(new_price)
    price_ratio = current_price > 0 ? (new_price - current_price) / current_price : 0
    [(available_quantity + (available_quantity * price_ratio * -0.3).round), 1].max
  end

  def clamp_price(price)
    floor = base_price * PRICE_FLOOR_MULTIPLIER
    ceiling = base_price * PRICE_CEILING_MULTIPLIER
    [price.clamp(floor, ceiling), 1.0].max.round(2)
  end

  # Get price for a specific day
  def price_on_day(day)
    price_histories.find_by(day: day)&.price
  end

  # Get quantity for a specific day
  def quantity_on_day(day)
    price_histories.find_by(day: day)&.quantity
  end

  # Record price in history table
  def record_price_for_day(day, price, quantity)
    price_histories.find_or_initialize_by(day: day).update!(price: price, quantity: quantity)
  end

  # Get price history as array for charting
  # Returns the most recent N prices in chronological order
  def price_history_array(days: 30)
    price_histories.order(day: :desc).limit(days).pluck(:price).reverse.map(&:to_f)
  end

  private

  def calculate_supply_pressure
    # Game-wide: compare current quantity to average
    avg = GameResource.where(game: game).average(:available_quantity).to_f
    return 0.0 if avg == 0
    ((1.0 - available_quantity / avg) * 0.3).clamp(-1.0, 1.0)
  end

  def calculate_demand_pressure
    player_qty = InventoryItem.where(game: game, resource: resource).sum(:quantity)
    if player_qty > available_quantity then 0.2
    elsif player_qty > 0 then 0.1
    else -0.05
    end
  end
end
