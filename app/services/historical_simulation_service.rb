class HistoricalSimulationService
  SIMULATION_DAYS = 30

  def initialize(game)
    @game = game
  end

  def call
    ActiveRecord::Base.transaction do
      # Pick the starting location first so we can use its population for quantity scaling
      @starting_location = Location.order("RANDOM()").first
      seed_game_resources
      simulate_historical_days
      reset_game_for_player_start
    end
  end

  private

  def seed_game_resources
    Resource.find_each do |resource|
      price = resource.generate_market_price

      @game.game_resources.create!(
        resource: resource,
        current_price: price,
        base_price: price,
        available_quantity: GameResource.calculate_initial_quantity(resource, price, location: @starting_location),
        price_direction: rand(-1.0..1.0).round(2),
        price_momentum: 0.5,
        sine_phase_offset: rand(0.0..(2.0 * Math::PI)).round(4),
        trend_phase_offset: rand(0.0..(2.0 * Math::PI)).round(4),
        last_refreshed_day: -SIMULATION_DAYS
      )
    end
  end

  def simulate_historical_days
    SIMULATION_DAYS.times do |i|
      historical_day = -(SIMULATION_DAYS - i)

      update_market_for_day(historical_day)
      spawn_events_for_day(historical_day)
      record_prices_for_day(historical_day)
      expire_events_for_day
    end
  end

  def update_market_for_day(day)
    @game.game_resources.find_each do |game_resource|
      update_resource_for_historical_day(game_resource, day)
    end
  end

  def update_resource_for_historical_day(game_resource, day)
    # Use the same sinusoidal price dynamics as GameResource
    new_price = game_resource.calculate_dynamic_price(day)
    new_quantity = game_resource.calculate_new_quantity(new_price)

    game_resource.update_columns(
      current_price: new_price,
      available_quantity: new_quantity,
      last_refreshed_day: day
    )
  end

  def spawn_events_for_day(day)
    EventSpawnerService.new(@game, day).spawn_if_eligible
  end

  def record_prices_for_day(day)
    @game.game_resources.find_each do |game_resource|
      game_resource.price_histories.create!(
        day: day,
        price: game_resource.current_price,
        quantity: game_resource.available_quantity
      )
    end
  end

  def expire_events_for_day
    @game.game_events.active.find_each do |game_event|
      game_event.decrement!(:days_remaining)
    end
  end

  def reset_game_for_player_start
    # Run one final market update for day 0 (the "current" state when player starts)
    update_market_for_day(0)
    record_prices_for_day(0)

    # Reset last_refreshed_day so day 1 will trigger a fresh market update
    @game.game_resources.update_all(last_refreshed_day: 0)

    @game.update_columns(
      current_day: 1,
      current_location_id: @starting_location.id
    )
  end
end
