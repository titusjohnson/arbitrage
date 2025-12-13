# == Schema Information
#
# Table name: location_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  base_price         :decimal(10, 2)
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  price_direction    :decimal(3, 2)    default(0.0), not null
#  price_momentum     :decimal(3, 2)    default(0.5), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  location_id        :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_location_resources_on_game_and_location  (game_id,location_id)
#  index_location_resources_on_game_id            (game_id)
#  index_location_resources_on_location_id        (location_id)
#  index_location_resources_on_resource_id        (resource_id)
#  index_location_resources_unique                (game_id,location_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#  resource_id  (resource_id => resources.id)
#
class LocationResource < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :location
  belongs_to :resource

  # Validations
  validates :current_price, presence: true, numericality: { greater_than: 0 }
  validates :last_refreshed_day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :resource_id, uniqueness: { scope: [:game_id, :location_id], message: "already exists at this location for this game" }

  # Scopes
  scope :for_game_and_location, ->(game, location) { where(game: game, location: location) }
  scope :fresh, ->(current_day) { where("last_refreshed_day >= ?", current_day - 1) }
  scope :stale, ->(current_day) { where("last_refreshed_day < ?", current_day - 1) }

  # Class methods
  def self.seed_for_location(game, location)
    # Don't re-seed if already seeded for this game/location
    return if exists?(game: game, location: location)

    resources_to_add = select_resources_for_location(location, game: game)

    transaction do
      resources_to_add.each do |resource|
        price = resource.generate_market_price
        quantity = calculate_initial_quantity(game, location, resource, price)

        create!(
          game: game,
          location: location,
          resource: resource,
          current_price: price,
          base_price: price, # Set base price for oscillation
          available_quantity: quantity,
          last_refreshed_day: game.current_day,
          price_direction: rand(-1.0..1.0).round(2), # Random initial direction
          price_momentum: 0.5 # Start with medium momentum
        )
      end
    end
  end

  def self.calculate_initial_quantity(game, location, resource, current_price)
    # 1. Base quantity by rarity
    base_qty = case resource.rarity
               when 'exceptional' then rand(1..3)
               when 'ultra_rare'  then rand(2..5)
               when 'rare'        then rand(5..15)
               when 'uncommon'    then rand(20..40)
               when 'common'      then rand(50..100)
               else rand(50..100) # fallback
               end

    # 2. Price modifier (expensive items are scarcer)
    price_mod = if current_price > 100_000
                  0.5  # Very expensive = half quantity
                elsif current_price > 10_000
                  0.7  # Expensive = reduced quantity
                elsif current_price > 1_000
                  1.0  # Normal = no change
                else
                  1.3  # Cheap = more abundant
                end

    # 3. Population modifier (larger cities have more stock)
    pop_mod = case location.population
              when 0..50_000       then 0.7
              when 50_001..200_000 then 1.0
              when 200_001..500_000 then 1.3
              else 1.5  # Major metros
              end

    # 4. Tag match bonus (specialty items get partial bonuses)
    resource_tags = resource.tag_names
    location_tags = location.tag_names
    matching_tags = (resource_tags & location_tags).size

    # Each matching tag adds 15% bonus (1-2 tags = 1.15-1.3x, 3+ tags = 1.45x+)
    tag_mod = 1.0 + (matching_tags * 0.15)

    # 5. Neighbor check (reduce quantity if neighbors already have this resource)
    neighbor_has_resource = game.location_resources
                                 .joins(:location)
                                 .where(location: location.neighbors, resource: resource)
                                 .exists?
    neighbor_mod = neighbor_has_resource ? 0.8 : 1.0

    # 6. Random variance ±20%
    variance = rand(0.8..1.2)

    # Calculate final quantity
    final_qty = (base_qty * price_mod * pop_mod * tag_mod * neighbor_mod * variance).round

    # Ensure minimum of 1
    [final_qty, 1].max
  end

  def self.select_resources_for_location(location, game: nil)
    location_tags = location.tag_names
    selected_resources = []

    # STEP 1: Get tag-matched resources (resources whose tags match location tags)
    # This creates thematic consistency (tech_hub has technology, port_city has imports, etc.)
    if location_tags.any?
      # Find resources that share tags with the location
      tagged_resources = Resource.tagged_with(names: location_tags, match: :any)

      # Sample based on rarity distribution for tagged resources
      selected_resources += sample_by_rarity(tagged_resources, target_count: 20)
    end

    # STEP 2: Sample 20% of adjacent location inventory (for trading opportunities)
    # This gives players immediate arbitrage opportunities between neighboring cities
    if game.present?
      neighbor_resources = LocationResource.joins(:location)
                                           .where(location: location.neighbors, game: game)
                                           .includes(:resource)
                                           .map(&:resource)
                                           .uniq

      if neighbor_resources.any?
        # Take ~20% of what neighbors have (minimum 2, maximum 8)
        sample_size = [(neighbor_resources.size * 0.2).ceil, 2].max
        sample_size = [sample_size, 8].min

        neighbor_sample = neighbor_resources.sample(sample_size)
        selected_resources += neighbor_sample
      end
    end

    # STEP 3: Add some random resources for variety (untagged or different tags)
    # This ensures every location has diversity and prevents predictability
    all_resources = Resource.all.to_a
    remaining_resources = all_resources - selected_resources

    random_count = [10, remaining_resources.size].min
    selected_resources += remaining_resources.sample(random_count)

    # STEP 4: Ensure minimum variety (at least 15 resources per location)
    if selected_resources.size < 15
      still_remaining = all_resources - selected_resources
      needed = 15 - selected_resources.size
      selected_resources += still_remaining.sample([needed, still_remaining.size].min)
    end

    selected_resources.uniq
  end

  def self.sample_by_rarity(resources_scope, target_count:)
    # Rarity distribution percentages (sum to ~100%)
    # Increased common/uncommon for more variety and trading opportunities
    # Common: 55%, Uncommon: 35%, Rare: 8%, Ultra Rare: 1.5%, Exceptional: 0.5%
    rarity_weights = {
      'common' => 0.55,
      'uncommon' => 0.35,
      'rare' => 0.08,
      'ultra_rare' => 0.015,
      'exceptional' => 0.005
    }

    selected = []
    resources_by_rarity = resources_scope.group_by(&:rarity)

    rarity_weights.each do |rarity, weight|
      next unless resources_by_rarity[rarity]&.any?

      # Calculate how many of this rarity to include
      count = (target_count * weight).round
      count = [count, 1].max if count > 0 # At least 1 if we're including this rarity

      available = resources_by_rarity[rarity]
      selected += available.sample([count, available.size].min)
    end

    # If we didn't hit target, randomly fill the rest
    if selected.size < target_count
      remaining = resources_scope.to_a - selected
      needed = target_count - selected.size
      selected += remaining.sample([needed, remaining.size].min)
    end

    selected
  end

  # Instance methods
  def needs_refresh?(current_day)
    last_refreshed_day < current_day
  end

  def refresh_price!(current_day)
    update!(
      current_price: resource.generate_market_price,
      last_refreshed_day: current_day
    )
  end

  # Updates price and quantity based on market dynamics
  # Creates parabolic price movements that shift over time
  def update_market_dynamics!(current_day)
    return if last_refreshed_day >= current_day

    # Calculate market forces
    supply_pressure = calculate_supply_pressure
    demand_pressure = calculate_demand_pressure
    momentum_decay = calculate_momentum_decay

    # Update price direction based on market forces
    new_direction = update_price_direction(supply_pressure, demand_pressure, momentum_decay)

    # Update momentum (gradually changes over time)
    new_momentum = update_price_momentum(new_direction)

    # Calculate new price based on direction and momentum
    new_price = calculate_new_price(new_direction, new_momentum)

    # Update quantity based on price movement
    new_quantity = calculate_new_quantity(new_price)

    # Apply updates
    update!(
      current_price: new_price,
      price_direction: new_direction,
      price_momentum: new_momentum,
      available_quantity: new_quantity,
      last_refreshed_day: current_day
    )
  end

  private

  # Calculate supply pressure across the entire game market
  # Returns a value between -1.0 (oversupply) and 1.0 (undersupply)
  def calculate_supply_pressure
    # Get total available quantity across all locations for this resource
    total_supply = LocationResource.where(game: game, resource: resource)
                                   .sum(:available_quantity)

    # Calculate average supply
    location_count = LocationResource.where(game: game, resource: resource).count
    return 0.0 if location_count == 0

    avg_supply = total_supply.to_f / location_count

    # Compare this location's supply to average
    # High local supply = negative pressure (prices should fall)
    # Low local supply = positive pressure (prices should rise)
    if avg_supply == 0
      0.0
    else
      supply_ratio = available_quantity.to_f / avg_supply
      # Convert ratio to pressure: 2x average = -0.5, 0.5x average = +0.5
      pressure = (1.0 - supply_ratio).clamp(-1.0, 1.0)
      pressure * 0.3 # Reduce impact to 30%
    end
  end

  # Calculate demand pressure based on player activity
  # Returns a value between -1.0 (low demand) and 1.0 (high demand)
  def calculate_demand_pressure
    # Check if player owns this resource (indicates demand)
    player_inventory = InventoryItem.where(game: game, resource: resource).sum(:quantity)

    # If player is hoarding this resource, demand increases
    if player_inventory > available_quantity
      0.2 # Moderate positive pressure
    elsif player_inventory > 0
      0.1 # Slight positive pressure
    else
      -0.05 # Slight negative pressure (no interest)
    end
  end

  # Calculate momentum decay - prices naturally slow down and reverse
  # Returns a value that pulls price_direction back toward 0
  def calculate_momentum_decay
    # Momentum decay is stronger when direction is extreme
    # This creates the turning point in the parabola
    decay_strength = price_direction.abs * 0.15

    # Decay pulls direction back toward zero
    if price_direction > 0
      -decay_strength
    elsif price_direction < 0
      decay_strength
    else
      0.0
    end
  end

  # Update price direction based on all market forces
  def update_price_direction(supply_pressure, demand_pressure, momentum_decay)
    # Volatility affects how much random forces influence direction
    volatility_factor = resource.price_volatility / 100.0
    random_force = rand(-0.2..0.2) * volatility_factor

    # Combine all forces
    total_force = supply_pressure + demand_pressure + momentum_decay + random_force

    # Apply force to current direction
    new_direction = price_direction + total_force

    # Clamp to valid range
    new_direction.clamp(-1.0, 1.0).round(2)
  end

  # Update momentum - gradually changes based on direction consistency
  def update_price_momentum(new_direction)
    # If direction changed sign, reduce momentum (direction reversal)
    if (price_direction * new_direction) < 0
      new_momentum = [price_momentum - 0.2, 0.1].max
    else
      # Same direction = increase momentum slightly
      new_momentum = [price_momentum + 0.05, 1.0].min
    end

    new_momentum.round(2)
  end

  # Calculate new price based on direction and momentum
  def calculate_new_price(new_direction, new_momentum)
    # Use base_price as the center point, fall back to current_price if not set
    center_price = base_price || current_price

    # Price volatility affects the range of movement
    volatility_factor = resource.price_volatility / 100.0

    # Maximum change per day is based on volatility and momentum
    # For a 30-day game, we want 3-5 complete cycles for medium volatility
    # So each cycle should be ~6-10 days
    max_daily_change = center_price * volatility_factor * 0.15

    # Actual change is direction * momentum * max_change
    price_change = new_direction * new_momentum * max_daily_change

    # Apply change to current price
    new_price = current_price + price_change

    # Ensure price stays within reasonable bounds (20% to 180% of base)
    min_price = center_price * 0.2
    max_price = center_price * 1.8

    # Never go below $1
    [new_price.clamp(min_price, max_price), 1.0].max.round(2)
  end

  # Calculate new quantity based on price movement
  def calculate_new_quantity(new_price)
    # When prices rise, supply tends to increase (producers produce more)
    # When prices fall, supply tends to decrease (producers hold back)

    price_change_ratio = if current_price > 0
      (new_price - current_price) / current_price
    else
      0.0
    end

    # Quantity changes in same direction as price, but dampened
    quantity_change = (available_quantity * price_change_ratio * 0.3).round

    # Apply change
    new_quantity = available_quantity + quantity_change

    # Ensure minimum of 0
    [new_quantity, 0].max
  end
end
