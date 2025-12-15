# Difficulty System Design

This document outlines the implementation plan for adding a difficulty selection system to the game. Players must choose a difficulty when starting a new game, which determines starting conditions, victory targets, and game duration.

## Overview

The difficulty system introduces:
1. **Pre-game difficulty selection** - Players choose difficulty before gameplay begins
2. **Difficulty modifiers** - Starting cash, wealth target, and day target vary by difficulty
3. **Historical simulation** - 30 days of simulated market history before player starts
4. **Price history seeding** - Realistic price movements during the historical period
5. **Event spawning during history** - Events trigger and resolve during the 30-day backfill

## Difficulty Levels

Five difficulty levels themed around trading, arbitrage, and travel industries:

| Level | Name | Starting Cash | Wealth Target | Day Target | Theme |
|-------|------|---------------|---------------|------------|-------|
| 1 | **Street Peddler** | $5,000 | $25,000 | 30 days | Small-time street vendor |
| 2 | **Flea Market Flipper** | $15,000 | $100,000 | 90 days | Weekend market reseller |
| 3 | **Antique Dealer** | $35,000 | $500,000 | 180 days | Established shop owner |
| 4 | **Commodities Broker** | $75,000 | $2,500,000 | 270 days | Professional trader |
| 5 | **Tycoon** | $100,000 | $10,000,000 | 365 days | Empire builder |

### Difficulty Modifier Configuration

Modifiers are stored in code only (not database) for simplicity and easy tuning:

```ruby
# app/models/concerns/difficulty_configuration.rb
module DifficultyConfiguration
  extend ActiveSupport::Concern

  DIFFICULTIES = {
    street_peddler: {
      display_name: "Street Peddler",
      description: "Start small, dream big. Perfect for learning the ropes.",
      starting_cash: 5_000,
      wealth_target: 25_000,
      day_target: 30,
      order: 1
    },
    flea_market_flipper: {
      display_name: "Flea Market Flipper",
      description: "You've got a booth and some seed money. Time to grow.",
      starting_cash: 15_000,
      wealth_target: 100_000,
      day_target: 90,
      order: 2
    },
    antique_dealer: {
      display_name: "Antique Dealer",
      description: "Your shop is established. Now make it legendary.",
      starting_cash: 35_000,
      wealth_target: 500_000,
      day_target: 180,
      order: 3
    },
    commodities_broker: {
      display_name: "Commodities Broker",
      description: "Big money, big risks. The markets await.",
      starting_cash: 75_000,
      wealth_target: 2_500_000,
      day_target: 270,
      order: 4
    },
    tycoon: {
      display_name: "Tycoon",
      description: "Build an empire. Only the relentless succeed.",
      starting_cash: 100_000,
      wealth_target: 10_000_000,
      day_target: 365,
      order: 5
    }
  }.freeze

  class_methods do
    def difficulty_options
      DIFFICULTIES.keys
    end

    def difficulty_config(level)
      DIFFICULTIES[level.to_sym]
    end
  end
end
```

## Database Changes

### Migration: Add Difficulty to Games

```ruby
class AddDifficultyToGames < ActiveRecord::Migration[8.0]
  def change
    add_column :games, :difficulty, :string, null: false, default: 'street_peddler'
    add_column :games, :wealth_target, :decimal, precision: 15, scale: 2, null: false, default: 25_000
    add_column :games, :day_target, :integer, null: false, default: 30
    
    add_index :games, :difficulty
  end
end
```

### Why Store `wealth_target` and `day_target` in the Database?

While difficulty modifiers are defined in code, we store `wealth_target` and `day_target` in the games table because:
1. **Victory condition evaluation** - These values are checked frequently during gameplay
2. **Historical preservation** - If we change difficulty settings, existing games keep their original targets
3. **Flexibility** - Allows for future features like custom games with player-defined targets

The `difficulty` column stores the difficulty key (e.g., `street_peddler`) for display and logging purposes.

## Game Creation Flow Changes

### Current Flow
1. User visits site
2. `GameSession` concern checks for existing game
3. If no game, creates one immediately with defaults
4. Game starts at day 1

### New Flow
1. User visits site
2. `GameSession` concern checks for existing game
3. If no game, redirect to difficulty selection page
4. User selects difficulty
5. Game is created with difficulty modifiers applied
6. **Historical simulation runs** (30 days of market activity)
7. Game day is reset to 1
8. Player starts in a random city with full price history

### GameSession Concern Changes

```ruby
# app/controllers/concerns/game_session.rb
module GameSession
  extend ActiveSupport::Concern

  included do
    before_action :load_or_create_game, except: [:new, :select_difficulty]
  end

  private

  def load_or_create_game
    if session[:game_restore_key].present?
      @current_game = Game.active.find_by(restore_key: session[:game_restore_key])
    end

    # Redirect to difficulty selection if no active game
    redirect_to new_game_path unless @current_game
  end

  def create_new_game(difficulty:)
    @current_game = Game.create_with_difficulty!(difficulty)
    session[:game_restore_key] = @current_game.restore_key
    @current_game
  end
end
```

## Historical Simulation Service

The core of this feature is a new service that simulates 30 days of market activity before the player starts.

### HistoricalSimulationService

```ruby
# app/services/historical_simulation_service.rb
class HistoricalSimulationService
  SIMULATION_DAYS = 30

  def initialize(game)
    @game = game
  end

  def call
    ActiveRecord::Base.transaction do
      seed_game_resources
      simulate_historical_days
      reset_game_for_player_start
    end
  end

  private

  def seed_game_resources
    GameResource.seed_for_game(@game)
  end

  def simulate_historical_days
    SIMULATION_DAYS.times do |day|
      historical_day = -(SIMULATION_DAYS - day) # Days -30 to -1
      
      # Update market dynamics for this day
      update_market_for_day(historical_day)
      
      # Potentially spawn events
      spawn_events_for_day(historical_day)
      
      # Record price history
      record_prices_for_day(historical_day)
      
      # Expire events that have run their course
      expire_events_for_day(historical_day)
    end
  end

  def update_market_for_day(day)
    @game.game_resources.find_each do |game_resource|
      game_resource.update_market_dynamics!(day)
    end
  end

  def spawn_events_for_day(day)
    EventSpawnerService.new(@game, day).spawn_if_eligible
  end

  def record_prices_for_day(day)
    @game.game_resources.find_each do |game_resource|
      game_resource.record_price_for_day(
        day,
        game_resource.current_price,
        game_resource.available_quantity
      )
    end
  end

  def expire_events_for_day(day)
    @game.game_events.active.find_each do |game_event|
      game_event.decrement!(:days_remaining)
    end
  end

  def reset_game_for_player_start
    @game.update!(
      current_day: 1,
      current_location: Location.order("RANDOM()").first
    )
    
    # Record day 0 as starting point
    record_prices_for_day(0)
  end
end
```

### Event Spawning During History

Events should spawn during the historical simulation using the same randomization rules as normal gameplay:

```ruby
# app/services/event_spawner_service.rb
class EventSpawnerService
  SPAWN_CHANCES = {
    common: 0.15,      # 15% chance per day
    uncommon: 0.08,    # 8% chance per day
    rare: 0.03,        # 3% chance per day
    ultra_rare: 0.01,  # 1% chance per day
    exceptional: 0.002 # 0.2% chance per day
  }.freeze

  def initialize(game, day)
    @game = game
    @day = day
  end

  def spawn_if_eligible
    # Don't spawn if there's already an active event
    return if @game.game_events.active.exists?

    Event.rarities.keys.each do |rarity|
      if should_spawn?(rarity)
        spawn_event(rarity)
        break # Only one event per day
      end
    end
  end

  private

  def should_spawn?(rarity)
    rand < SPAWN_CHANCES[rarity.to_sym]
  end

  def spawn_event(rarity)
    event = Event.active.where(rarity: rarity).order("RANDOM()").first
    return unless event

    @game.game_events.create!(
      event: event,
      day_triggered: @day,
      days_remaining: event.duration,
      seen: @day < 0 # Auto-mark historical events as seen
    )
  end
end
```

## Price History Considerations

### Negative Days for Historical Data

Price history will use negative day numbers for historical data:
- Day -30 through Day -1: Historical simulation period
- Day 0: Starting state when player begins
- Day 1+: Active gameplay

This allows the existing `ResourcePriceHistory` model to work unchanged, and the UI can display historical trends without special handling.

### Migration for Price History Index

```ruby
class UpdateResourcePriceHistoryForNegativeDays < ActiveRecord::Migration[8.0]
  def change
    # Ensure the unique constraint allows negative days
    # Current constraint should already support this, but verify
    remove_index :resource_price_histories, 
                 [:game_resource_id, :day], 
                 if_exists: true
    
    add_index :resource_price_histories, 
              [:game_resource_id, :day], 
              unique: true
  end
end
```

## Game Model Changes

### Updated Game Model

```ruby
# app/models/game.rb
class Game < ApplicationRecord
  include DifficultyConfiguration
  
  # Existing code...
  
  enum :difficulty, {
    street_peddler: 'street_peddler',
    flea_market_flipper: 'flea_market_flipper',
    antique_dealer: 'antique_dealer',
    commodities_broker: 'commodities_broker',
    tycoon: 'tycoon'
  }
  
  validates :difficulty, presence: true
  validates :wealth_target, numericality: { greater_than: 0 }
  validates :day_target, numericality: { greater_than: 0, only_integer: true }
  
  def self.create_with_difficulty!(difficulty_key)
    config = difficulty_config(difficulty_key)
    raise ArgumentError, "Unknown difficulty: #{difficulty_key}" unless config
    
    game = create!(
      difficulty: difficulty_key,
      cash: config[:starting_cash],
      wealth_target: config[:wealth_target],
      day_target: config[:day_target]
    )
    
    # Run historical simulation
    HistoricalSimulationService.new(game).call
    
    game
  end
  
  def victory?
    net_worth >= wealth_target
  end
  
  def days_remaining
    day_target - current_day
  end
  
  def time_expired?
    current_day > day_target
  end
  
  def difficulty_display_name
    self.class.difficulty_config(difficulty)[:display_name]
  end
end
```

## Controllers

### GamesController for Difficulty Selection

```ruby
# app/controllers/games_controller.rb
class GamesController < ApplicationController
  skip_before_action :load_or_create_game, only: [:new, :create]
  
  def new
    # Difficulty selection page
    @difficulties = Game::DIFFICULTIES
  end
  
  def create
    difficulty = params[:difficulty]&.to_sym
    
    unless Game.difficulty_options.include?(difficulty)
      redirect_to new_game_path, alert: "Please select a valid difficulty."
      return
    end
    
    create_new_game(difficulty: difficulty)
    redirect_to dashboard_path, notice: "Game started on #{@current_game.difficulty_display_name} difficulty!"
  end
  
  def show
    # Existing game dashboard
  end
end
```

## Views

### Difficulty Selection Page

```erb
<!-- app/views/games/new.html.erb -->
<div class="difficulty-selection">
  <h1>Choose Your Difficulty</h1>
  <p class="difficulty-intro">Select how challenging you want your trading journey to be.</p>
  
  <div class="difficulty-grid">
    <% Game::DIFFICULTIES.each do |key, config| %>
      <%= link_to games_path(difficulty: key), method: :post, class: "difficulty-card difficulty-card--#{key}" do %>
        <h2 class="difficulty-card__name"><%= config[:display_name] %></h2>
        <p class="difficulty-card__description"><%= config[:description] %></p>
        
        <div class="difficulty-card__stats">
          <div class="difficulty-card__stat">
            <span class="difficulty-card__stat-label">Starting Cash</span>
            <span class="difficulty-card__stat-value"><%= number_to_currency(config[:starting_cash]) %></span>
          </div>
          <div class="difficulty-card__stat">
            <span class="difficulty-card__stat-label">Wealth Target</span>
            <span class="difficulty-card__stat-value"><%= number_to_currency(config[:wealth_target]) %></span>
          </div>
          <div class="difficulty-card__stat">
            <span class="difficulty-card__stat-label">Time Limit</span>
            <span class="difficulty-card__stat-value"><%= pluralize(config[:day_target], 'day') %></span>
          </div>
        </div>
      <% end %>
    <% end %>
  </div>
</div>
```

## Implementation Steps

### Phase 1: Database & Model Foundation
1. Create migration to add `difficulty`, `wealth_target`, and `day_target` to games table
2. Create `DifficultyConfiguration` concern with difficulty definitions
3. Update `Game` model with difficulty enum, validations, and helper methods
4. Update existing tests to specify difficulty

### Phase 2: Historical Simulation
1. Create `HistoricalSimulationService` class
2. Create `EventSpawnerService` class for event spawning logic
3. Modify `GameResource#record_price_for_day` to support negative days
4. Update `GameResource.seed_for_game` to not generate initial history (simulation handles it)
5. Add `Game.create_with_difficulty!` class method

### Phase 3: Game Creation Flow
1. Update `GameSession` concern to redirect to difficulty selection
2. Create `GamesController` with `new` and `create` actions
3. Add routes for game creation
4. Create difficulty selection view

### Phase 4: Victory Conditions
1. Update `GameTurnAction` to check victory conditions against `wealth_target`
2. Update day limit checks to use `day_target` instead of hardcoded 30
3. Update game completion logic

### Phase 5: UI Updates
1. Display difficulty level and targets in game dashboard
2. Show progress toward wealth target
3. Display days remaining based on `day_target`
4. Style difficulty selection page per STYLE_GUIDE.md

### Phase 6: Testing
1. Unit tests for `DifficultyConfiguration`
2. Unit tests for `HistoricalSimulationService`
3. Unit tests for `EventSpawnerService`
4. Integration tests for game creation flow
5. System tests for difficulty selection UI

## Files to Create/Modify

### New Files
- `app/models/concerns/difficulty_configuration.rb`
- `app/services/historical_simulation_service.rb`
- `app/services/event_spawner_service.rb`
- `app/controllers/games_controller.rb`
- `app/views/games/new.html.erb`
- `db/migrate/XXXXXX_add_difficulty_to_games.rb`
- `spec/models/concerns/difficulty_configuration_spec.rb`
- `spec/services/historical_simulation_service_spec.rb`
- `spec/services/event_spawner_service_spec.rb`

### Modified Files
- `app/models/game.rb` - Add difficulty support
- `app/models/game_resource.rb` - Remove initial history generation (simulation handles it)
- `app/controllers/concerns/game_session.rb` - Redirect to difficulty selection
- `app/controllers/application_controller.rb` - May need adjustments
- `config/routes.rb` - Add game creation routes
- `app/views/layouts/application.html.erb` - Display difficulty/progress
- `spec/factories/games.rb` - Add difficulty trait

## Performance Considerations

### Historical Simulation Speed
Simulating 30 days for 70 resources means:
- 70 resources × 30 days = 2,100 price history records
- 30 event spawn checks
- 2,100 market dynamic updates

This should complete in under 2 seconds on typical hardware. To optimize if needed:
- Use `insert_all` for bulk price history creation
- Batch market updates
- Run simulation in a background job if latency is unacceptable

### Database Indexes
Existing indexes should handle queries well:
- `game_resources.game_id` - for loading all resources
- `resource_price_histories.(game_resource_id, day)` - for price lookups

## Future Enhancements

### Potential Additions (Not in Scope)
- Custom difficulty with player-defined targets
- Difficulty-specific events
- Leaderboards per difficulty
- Difficulty-based achievements
- Scaling event severity by difficulty
- Market volatility adjustments per difficulty

These are intentionally left out to keep the initial implementation focused.

## Summary

This design adds a difficulty system that:
1. Requires players to choose difficulty before starting
2. Applies appropriate starting conditions based on selection
3. Simulates 30 days of market history for a realistic start
4. Maintains all existing game mechanics unchanged
5. Stores difficulty settings in code for easy tuning
6. Persists victory targets in database for game integrity

The implementation is designed to be minimally invasive to existing code while providing a foundation for future difficulty-related features.
