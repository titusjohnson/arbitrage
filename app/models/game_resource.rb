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
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_game_resources_unique  (game_id,resource_id) UNIQUE
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

  # Validations
  validates :current_price, presence: true, numericality: { greater_than: 0 }
  validates :base_price, presence: true, numericality: { greater_than: 0 }
  validates :last_refreshed_day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :resource_id, uniqueness: { scope: :game_id, message: "already exists for this game" }

  # Scopes
  scope :for_game, ->(game) { where(game: game) }
  scope :fresh, ->(current_day) { where("last_refreshed_day >= ?", current_day - 1) }
  scope :stale, ->(current_day) { where("last_refreshed_day < ?", current_day - 1) }

  # Seed all resources for a new game
  def self.seed_for_game(game)
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
          last_refreshed_day: game.current_day
        )

        # Generate initial price history
        game_resource.generate_initial_history(days: 30)
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

  # Generate historical prices before game start
  def generate_initial_history(days: 30)
    current = base_price * rand(0.8..1.2)
    direction = rand(-1.0..1.0)
    momentum = rand(0.3..0.7)
    quantity = available_quantity

    (1..days).each do |day|
      price_histories.create!(day: day, price: current.round(2), quantity: quantity)

      # Simulate price movement
      volatility = resource.price_volatility / 100.0
      decay = direction.abs * 0.15 * (direction > 0 ? -1 : 1)
      random = rand(-0.2..0.2) * volatility

      direction = (direction + decay + random).clamp(-1.0, 1.0)
      momentum = direction != 0 ? [momentum + 0.05, 1.0].min : [momentum - 0.1, 0.1].max

      price_change = direction * momentum * base_price * volatility * 0.15
      current = (current + price_change).clamp(base_price * 0.2, base_price * 1.8)
      current = [current, 1.0].max

      quantity = [(quantity + (quantity * price_change / current * 0.3)).round, 0].max
    end
  end

  def needs_refresh?(current_day)
    last_refreshed_day < current_day
  end

  # Daily price update
  def update_market_dynamics!(current_day)
    return if last_refreshed_day >= current_day

    # Calculate forces
    supply_pressure = calculate_supply_pressure
    demand_pressure = calculate_demand_pressure
    momentum_decay = price_direction.abs * 0.15 * (price_direction > 0 ? -1 : 1)

    # Update direction
    volatility = resource.price_volatility / 100.0
    random = rand(-0.2..0.2) * volatility
    new_direction = (price_direction + supply_pressure + demand_pressure + momentum_decay + random).clamp(-1.0, 1.0).round(2)

    # Update momentum
    new_momentum = if (price_direction * new_direction) < 0
                     [price_momentum - 0.2, 0.1].max
                   else
                     [price_momentum + 0.05, 1.0].min
                   end.round(2)

    # Calculate new price
    max_change = base_price * volatility * 0.15
    price_change = new_direction * new_momentum * max_change
    new_price = (current_price + price_change).clamp(base_price * 0.2, base_price * 1.8)
    new_price = [new_price, 1.0].max.round(2)

    # Update quantity
    price_ratio = current_price > 0 ? (new_price - current_price) / current_price : 0
    new_quantity = [(available_quantity + (available_quantity * price_ratio * 0.3).round), 0].max

    update!(
      current_price: new_price,
      price_direction: new_direction,
      price_momentum: new_momentum,
      available_quantity: new_quantity,
      last_refreshed_day: current_day
    )

    # Record in history table
    record_price_for_day(current_day, new_price, new_quantity)
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
  def price_history_array(days: 30)
    history_hash = price_histories.pluck(:day, :price).to_h
    (1..days).map { |day| history_hash[day]&.to_f }
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
