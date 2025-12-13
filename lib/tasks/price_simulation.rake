namespace :prices do
  desc "Simulate and display price movements over 30 days"
  task simulate: :environment do
    puts "\n=== Price Dynamics Simulation ==="
    puts "Simulating 30 days of price movements for different volatility levels\n\n"

    # Create a test game
    game = Game.create!(
      current_day: 1,
      cash: 10000,
      status: 'active',
      started_at: Time.current,
      restore_key: SecureRandom.uuid
    )

    location = Location.first || Location.create!(
      name: "Test City",
      x: 0,
      y: 0,
      population: 100000
    )

    game.update!(current_location: location)

    # Test three resources with different volatilities
    resources = [
      { name: "Stable Gold", volatility: 10, color: "🟡" },
      { name: "Medium Stock", volatility: 50, color: "🔵" },
      { name: "Volatile Crypto", volatility: 90, color: "🔴" }
    ]

    location_resources = resources.map do |res_config|
      resource = Resource.create!(
        name: res_config[:name],
        description: "Test resource",
        base_price_min: 90,
        base_price_max: 110,
        price_volatility: res_config[:volatility],
        inventory_size: 1,
        rarity: 'common'
      )

      LocationResource.create!(
        game: game,
        location: location,
        resource: resource,
        current_price: 100.0,
        base_price: 100.0,
        available_quantity: 50,
        price_direction: rand(-0.5..0.5).round(2),
        price_momentum: 0.5,
        last_refreshed_day: 1
      )
    end

    # Print header
    puts "Day | " + resources.map { |r| "#{r[:color]} #{r[:name].ljust(16)}" }.join(" | ")
    puts "-" * 80

    # Simulate 30 days
    price_history = resources.map { |_| [] }

    30.times do |day|
      day_num = day + 1
      game.update!(current_day: day_num)

      # Update each location resource
      location_resources.each do |lr|
        lr.update_market_dynamics!(day_num)
      end

      # Print current prices
      day_str = "#{day_num.to_s.rjust(3)} | "
      price_strs = location_resources.map.with_index do |lr, idx|
        price = lr.current_price
        direction = lr.price_direction
        momentum = lr.price_momentum

        price_history[idx] << price

        arrow = direction > 0 ? "↑" : direction < 0 ? "↓" : "→"
        momentum_bar = "█" * (momentum * 5).round

        "#{price.to_s.rjust(7, ' ')} #{arrow} #{momentum_bar.ljust(5)}"
      end

      puts day_str + price_strs.join(" | ")
    end

    # Print summary statistics
    puts "\n=== Summary Statistics ==="
    location_resources.each_with_index do |lr, idx|
      prices = price_history[idx]
      min_price = prices.min
      max_price = prices.max
      avg_price = (prices.sum / prices.size).round(2)
      price_range = max_price - min_price
      volatility_pct = ((price_range / 100.0) * 100).round(2)

      puts "\n#{resources[idx][:color]} #{resources[idx][:name]}:"
      puts "  Min Price: $#{min_price.round(2)}"
      puts "  Max Price: $#{max_price.round(2)}"
      puts "  Avg Price: $#{avg_price}"
      puts "  Range: $#{price_range.round(2)} (#{volatility_pct}% of base)"
      puts "  Final Direction: #{lr.price_direction > 0 ? 'Rising' : 'Falling'} (#{lr.price_direction})"
      puts "  Final Momentum: #{(lr.price_momentum * 100).round(0)}%"
    end

    # Clean up
    game.destroy
    resources.each do |res_config|
      Resource.find_by(name: res_config[:name])&.destroy
    end

    puts "\n✓ Simulation complete!\n\n"
  end
end
