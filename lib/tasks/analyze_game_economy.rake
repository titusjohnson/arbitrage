namespace :economy do
  desc "Statistical analysis of game economy to determine optimal starting cash"
  task analyze: :environment do
    puts "=" * 80
    puts "GAME ECONOMY STATISTICAL ANALYSIS"
    puts "=" * 80
    puts

    analyzer = EconomyAnalyzer.new
    analyzer.run_full_analysis
  end
end

class EconomyAnalyzer
  SIMULATION_COUNT = 30 # Max locations on 6x5 grid (0-5, 0-4)
  INVENTORY_CAPACITY = 100
  TARGET_INVENTORY_FILL = 50 # 50% of capacity
  MAX_TURNS_TO_FILL = 2
  PROFIT_RECOVERY_TURNS = 5
  TARGET_PROFIT_RECOVERY = 0.5 # 50% of starting capital

  def run_full_analysis
    puts "Simulation Parameters:"
    puts "  - Locations to generate: #{SIMULATION_COUNT}"
    puts "  - Inventory capacity: #{INVENTORY_CAPACITY}"
    puts "  - Target inventory fill: #{TARGET_INVENTORY_FILL}% (#{INVENTORY_CAPACITY * TARGET_INVENTORY_FILL / 100} units)"
    puts "  - Turns to fill inventory: #{MAX_TURNS_TO_FILL}"
    puts "  - Profit recovery analysis: #{PROFIT_RECOVERY_TURNS} turns"
    puts "  - Target profit recovery: #{(TARGET_PROFIT_RECOVERY * 100).to_i}% of starting capital"
    puts
    puts "-" * 80
    puts

    # Step 1: Analyze resource pricing
    analyze_resource_pricing

    # Step 2: Generate test locations and analyze markets
    location_data = generate_and_analyze_locations

    # Step 3: Calculate optimal starting cash
    optimal_cash = calculate_optimal_starting_cash(location_data)

    # Step 4: Run profit simulations
    run_profit_simulations(location_data, optimal_cash)

    # Step 5: Provide recommendations
    provide_recommendations(optimal_cash)
  end

  private

  def analyze_resource_pricing
    puts "STEP 1: Resource Pricing Analysis"
    puts "-" * 80

    resources = Resource.all

    prices = resources.map(&:average_price).sort
    inventory_sizes = resources.map(&:inventory_size).sort

    puts "Total resources in database: #{resources.count}"
    puts
    puts "Price Distribution:"
    puts "  Min average price: $#{prices.min.round(2)}"
    puts "  Max average price: $#{prices.max.round(2)}"
    puts "  Median average price: $#{median(prices).round(2)}"
    puts "  Mean average price: $#{mean(prices).round(2)}"
    puts "  25th percentile: $#{percentile(prices, 25).round(2)}"
    puts "  75th percentile: $#{percentile(prices, 75).round(2)}"
    puts
    puts "Inventory Size Distribution:"
    puts "  Min size: #{inventory_sizes.min}"
    puts "  Max size: #{inventory_sizes.max}"
    puts "  Median size: #{median(inventory_sizes)}"
    puts "  Mean size: #{mean(inventory_sizes).round(2)}"
    puts
    puts "Rarity Distribution:"
    Resource.group(:rarity).count.each do |rarity, count|
      pct = (count.to_f / resources.count * 100).round(1)
      puts "  #{rarity.titleize}: #{count} (#{pct}%)"
    end
    puts
  end

  def generate_and_analyze_locations
    puts "STEP 2: Analyzing Markets Across Locations"
    puts "-" * 80

    location_data = []

    # Use existing locations from database
    existing_locations = Location.all.to_a

    if existing_locations.empty?
      puts "ERROR: No locations found in database. Please seed the database first."
      return []
    end

    puts "Using #{existing_locations.count} existing locations from database"

    # Create temporary game for simulation
    game = Game.create!(
      cash: 1_000_000, # High cash to not limit analysis
      restore_key: "economy_analysis_#{SecureRandom.hex(8)}"
    )

    existing_locations.each_with_index do |location, i|
      # Seed resources for this location
      LocationResource.seed_for_location(game, location)

      # Collect pricing data
      location_resources = LocationResource.for_game_and_location(game, location).includes(:resource)

      prices = location_resources.map(&:current_price).sort
      sizes = location_resources.map { |lr| lr.resource.inventory_size }.sort

      # Calculate cost metrics
      median_price = median(prices)
      median_size = median(sizes)

      # Cost to buy median-priced, median-sized items
      cost_per_inventory_unit = median_price / median_size

      location_data << {
        location: location,
        resource_count: location_resources.count,
        median_price: median_price,
        mean_price: mean(prices),
        min_price: prices.min,
        max_price: prices.max,
        median_size: median_size,
        cost_per_inventory_unit: cost_per_inventory_unit,
        location_resources: location_resources
      }

      print "." if (i + 1) % 10 == 0
    end

    puts " Done!"
    puts

    # Aggregate statistics
    all_median_prices = location_data.map { |d| d[:median_price] }
    all_costs_per_unit = location_data.map { |d| d[:cost_per_inventory_unit] }

    puts "Market Analysis (#{location_data.count} locations):"
    puts "  Median price across all locations:"
    puts "    Min: $#{all_median_prices.min.round(2)}"
    puts "    Max: $#{all_median_prices.max.round(2)}"
    puts "    Median: $#{median(all_median_prices).round(2)}"
    puts "    Mean: $#{mean(all_median_prices).round(2)}"
    puts
    puts "  Cost per inventory unit:"
    puts "    Min: $#{all_costs_per_unit.min.round(2)}"
    puts "    Max: $#{all_costs_per_unit.max.round(2)}"
    puts "    Median: $#{median(all_costs_per_unit).round(2)}"
    puts "    Mean: $#{mean(all_costs_per_unit).round(2)}"
    puts

    # Cleanup test game
    game.destroy!

    location_data
  end

  def calculate_optimal_starting_cash(location_data)
    puts "STEP 3: Calculating Optimal Starting Cash"
    puts "-" * 80

    # Goal: 50% chance to fill 50% of inventory in 2 turns
    # Strategy: Find the cash amount where median player can achieve this

    target_inventory_size = INVENTORY_CAPACITY * TARGET_INVENTORY_FILL / 100

    # Simulate purchasing at each location
    costs_to_fill = []

    location_data.each do |data|
      # Sort resources by price/efficiency
      resources_by_value = data[:location_resources].sort_by do |lr|
        # Prioritize: low price, small size, common rarity
        efficiency = lr.current_price.to_f / lr.resource.inventory_size
        efficiency
      end

      # Simulate filling inventory to target
      total_cost = 0
      inventory_filled = 0
      purchases = 0

      resources_by_value.each do |lr|
        break if inventory_filled >= target_inventory_size
        break if purchases >= MAX_TURNS_TO_FILL # Assume 1 purchase per turn

        resource = lr.resource
        space_remaining = target_inventory_size - inventory_filled

        # How many can we fit?
        max_quantity = space_remaining / resource.inventory_size
        quantity_to_buy = [max_quantity, 1].max # Buy at least 1

        cost = lr.current_price * quantity_to_buy
        total_cost += cost
        inventory_filled += resource.inventory_size * quantity_to_buy
        purchases += 1
      end

      costs_to_fill << total_cost
    end

    costs_to_fill.sort!

    puts "Cost to fill #{TARGET_INVENTORY_FILL}% of inventory in #{MAX_TURNS_TO_FILL} turns:"
    puts "  Min cost: $#{costs_to_fill.min.round(2)}"
    puts "  Max cost: $#{costs_to_fill.max.round(2)}"
    puts "  Median cost (50th percentile): $#{median(costs_to_fill).round(2)}"
    puts "  75th percentile: $#{percentile(costs_to_fill, 75).round(2)}"
    puts "  90th percentile: $#{percentile(costs_to_fill, 90).round(2)}"
    puts

    # For 50% success rate, use median
    # Add buffer for price variations and bad luck
    base_cost = median(costs_to_fill)
    buffer_multiplier = 1.5 # 50% buffer
    optimal_cash = (base_cost * buffer_multiplier).round(-2) # Round to nearest 100

    puts "Recommended starting cash calculation:"
    puts "  Base cost (median): $#{base_cost.round(2)}"
    puts "  Buffer multiplier: #{buffer_multiplier}x"
    puts "  Optimal starting cash: $#{optimal_cash}"
    puts

    optimal_cash
  end

  def run_profit_simulations(location_data, starting_cash)
    puts "STEP 4: Profit Recovery Simulation"
    puts "-" * 80

    # Simulate: player starts with starting_cash, fills inventory
    # Then travels to nearby locations and attempts to profit

    target_profit = starting_cash * TARGET_PROFIT_RECOVERY
    success_count = 0

    puts "Simulating #{location_data.count} scenarios..."
    puts "  Starting cash: $#{starting_cash}"
    puts "  Target profit: $#{target_profit} (#{(TARGET_PROFIT_RECOVERY * 100).to_i}% recovery)"
    puts "  Turns to achieve: #{PROFIT_RECOVERY_TURNS}"
    puts

    location_data.each_with_index do |start_data, idx|
      # Player starts here and buys inventory
      purchased_items = []
      remaining_cash = starting_cash
      inventory_filled = 0

      # Phase 1: Buy at starting location
      start_data[:location_resources].sort_by { |lr| lr.current_price.to_f / lr.resource.inventory_size }.each do |lr|
        break if inventory_filled >= INVENTORY_CAPACITY / 2

        resource = lr.resource
        space_remaining = (INVENTORY_CAPACITY / 2) - inventory_filled
        max_quantity = space_remaining / resource.inventory_size
        quantity = [max_quantity, 1].max

        cost = lr.current_price * quantity
        break if cost > remaining_cash

        remaining_cash -= cost
        inventory_filled += resource.inventory_size * quantity

        purchased_items << {
          resource: resource,
          quantity: quantity,
          purchase_price: lr.current_price,
          purchase_location_idx: idx
        }
      end

      # Phase 2: Visit nearby locations and try to sell for profit
      best_profit = 0

      # Check a few "nearby" locations (simulate travel)
      nearby_count = [PROFIT_RECOVERY_TURNS, location_data.count - 1].min
      nearby_locations = location_data.sample(nearby_count).reject { |d| d == start_data }

      nearby_locations.each do |dest_data|
        scenario_profit = 0

        # Try to sell each purchased item at this location
        purchased_items.each do |item|
          # Find this resource at destination
          dest_lr = dest_data[:location_resources].find { |lr| lr.resource_id == item[:resource].id }
          next unless dest_lr # Resource not available at destination

          sell_price = dest_lr.current_price
          profit_per_unit = sell_price - item[:purchase_price]
          total_profit = profit_per_unit * item[:quantity]

          scenario_profit += total_profit if total_profit > 0
        end

        best_profit = scenario_profit if scenario_profit > best_profit
      end

      success_count += 1 if best_profit >= target_profit
    end

    success_rate = (success_count.to_f / location_data.count * 100).round(1)

    puts "Results:"
    puts "  Successful scenarios: #{success_count}/#{location_data.count}"
    puts "  Success rate: #{success_rate}%"
    puts "  (Success = achieving #{(TARGET_PROFIT_RECOVERY * 100).to_i}% profit recovery in #{PROFIT_RECOVERY_TURNS} turns)"
    puts
  end

  def provide_recommendations(optimal_cash)
    puts "=" * 80
    puts "RECOMMENDATIONS"
    puts "=" * 80
    puts
    puts "Based on statistical analysis of real-world location markets:"
    puts
    puts "1. STARTING CASH: $#{optimal_cash.to_i}"
    puts "   This amount gives players a ~50% chance to:"
    puts "   - Fill #{TARGET_INVENTORY_FILL}% of inventory (#{INVENTORY_CAPACITY * TARGET_INVENTORY_FILL / 100} units) within #{MAX_TURNS_TO_FILL} turns"
    puts "   - Have enough buffer for price variance"
    puts
    puts "2. Alternative recommendations:"
    puts "   - Conservative (easier): $#{(optimal_cash * 1.3).round(-2).to_i} (30% more)"
    puts "   - Aggressive (harder): $#{(optimal_cash * 0.7).round(-2).to_i} (30% less)"
    puts
    puts "3. Update Game model:"
    puts "   Change default cash from $2,000 to $#{optimal_cash.to_i}"
    puts
    puts "To apply the recommended change, run:"
    puts "  rails db:migrate:reset"
    puts "  # Then update db/schema.rb cash default value"
    puts
  end

  # Statistical helper methods
  def mean(array)
    return 0 if array.empty?
    array.sum.to_f / array.length
  end

  def median(array)
    return 0 if array.empty?
    sorted = array.sort
    len = sorted.length
    (sorted[(len - 1) / 2] + sorted[len / 2]) / 2.0
  end

  def percentile(array, p)
    return 0 if array.empty?
    sorted = array.sort
    k = (p / 100.0) * (sorted.length - 1)
    f = k.floor
    c = k.ceil

    if f == c
      sorted[k.to_i]
    else
      sorted[f] * (c - k) + sorted[c] * (k - f)
    end
  end
end
