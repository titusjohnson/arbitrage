# Price Dynamics System

## Overview

The game features a realistic price fluctuation system that creates parabolic price movements over time. Prices naturally rise and fall in cycles, influenced by supply, demand, and market momentum.

## How It Works

### When Prices Update

Prices and quantities update automatically when the player travels to a new location via `GameTurnAction`. This action:
1. Runs after the player arrives at their destination
2. Updates all `LocationResource` prices and quantities across the entire game
3. Applies real-world economic pressures to create realistic market dynamics

### Price Tracking Fields

Each `LocationResource` tracks:

- **`base_price`** - The center point around which prices oscillate (set when resource first appears at location)
- **`current_price`** - The current market price (updated each turn)
- **`price_direction`** - Direction of price movement (-1.0 = falling, +1.0 = rising)
- **`price_momentum`** - Speed/strength of price changes (0.0 = slow, 1.0 = fast)

### Market Forces

Four forces influence price movements:

#### 1. Supply Pressure (30% impact)
- Compares local supply to game-wide average
- **High local supply** → negative pressure → prices fall
- **Low local supply** → positive pressure → prices rise
- Example: If a location has 2x the average supply, prices tend to drop

#### 2. Demand Pressure (up to 20% impact)
- Based on player inventory holdings
- **Player hoarding resource** → +0.2 pressure → prices rise
- **Player owns some** → +0.1 pressure → slight rise
- **Player owns none** → -0.05 pressure → slight fall

#### 3. Momentum Decay (15% of direction)
- Naturally slows and reverses price trends
- **Stronger at extremes** → creates turning points
- This creates the parabolic effect:
  - Prices rise → slow down → reverse → fall
  - Prices fall → slow down → reverse → rise

#### 4. Random Forces (varies by volatility)
- Adds unpredictability based on resource's `price_volatility`
- High volatility = larger random swings
- Low volatility = smaller random swings

### Price Movement Calculation

```ruby
# 1. Calculate all forces
supply_pressure = compare_to_market_average()
demand_pressure = check_player_inventory()
momentum_decay = calculate_reversal_force()
random_force = rand() * volatility

# 2. Update direction
new_direction = current_direction + (supply + demand + decay + random)

# 3. Update momentum
if direction_reversed?
  momentum -= 0.2  # Slow down on reversal
else
  momentum += 0.05  # Speed up on continuation
end

# 4. Calculate price change
max_change = base_price * volatility * 0.15
price_change = direction * momentum * max_change

# 5. Apply bounds
new_price = clamp(current_price + price_change, base_price * 0.2, base_price * 1.8)
new_price = max(new_price, 1.0)  # Never below $1
```

### Quantity Updates

Supply adjusts in response to price changes:
- **Prices rising** → suppliers produce more → quantity increases
- **Prices falling** → suppliers hold back → quantity decreases
- Change is dampened at 30% to prevent wild swings

## Game Balance

For a 30-day game with medium volatility (50):
- **3-5 complete price cycles** occur per resource
- Each cycle takes approximately **6-10 days**
- Players see multiple opportunities to buy low and sell high
- High volatility resources cycle faster
- Low volatility resources cycle slower

### Volatility Effects

| Volatility | Cycle Speed | Price Range | Trading Strategy |
|------------|-------------|-------------|------------------|
| 10 (Low) | Slow, stable | Narrow swings | Long-term holds |
| 50 (Medium) | Moderate | Medium swings | Standard trading |
| 90 (High) | Fast, chaotic | Wide swings | Quick flips, risky |

## Examples

### Example 1: Common Resource (Volatility: 50)
- **Day 1**: $100, direction +0.5, momentum 0.5
- **Day 2**: $107.50, direction +0.6, momentum 0.55 (rising)
- **Day 3**: $115.88, direction +0.65, momentum 0.6 (accelerating)
- **Day 5**: $125.00, direction +0.4, momentum 0.45 (slowing)
- **Day 7**: $125.50, direction +0.1, momentum 0.3 (peak)
- **Day 9**: $122.00, direction -0.15, momentum 0.25 (reversing)
- **Day 12**: $110.00, direction -0.5, momentum 0.4 (falling)

### Example 2: High Volatility Resource (Volatility: 90)
- **Day 1**: $500, direction +0.8, momentum 0.7
- **Day 2**: $556 (large jump, 11.2% increase)
- **Day 3**: $618 (continuing fast rise)
- **Day 4**: $540 (sudden reversal)
- **Day 6**: $450 (rapid fall)

## Trading Strategies

### Buy Low, Sell High
1. Watch for resources with negative direction (falling prices)
2. Buy when momentum starts reversing (near bottom of parabola)
3. Travel to high-demand locations
4. Sell when direction becomes positive and momentum is high

### Arbitrage
1. Check neighboring locations for price differences
2. Supply pressure creates regional variations
3. Buy in oversupplied markets
4. Sell in undersupplied markets

### Momentum Trading
1. Buy resources with positive direction and rising momentum
2. Ride the wave until momentum peaks
3. Sell before reversal

## Implementation Details

### Files
- **`app/services/game_turn_action.rb`** - Triggers market updates on travel
- **`app/models/location_resource.rb`** - Contains all price calculation logic
- **Migration**: `db/migrate/*_add_price_tracking_to_location_resources.rb`

### Key Methods
- `LocationResource#update_market_dynamics!(current_day)` - Main update method
- `LocationResource#calculate_supply_pressure` - Market supply analysis
- `LocationResource#calculate_demand_pressure` - Player inventory analysis
- `LocationResource#calculate_momentum_decay` - Parabolic reversal force
- `LocationResource#calculate_new_price` - Final price calculation

### Integration
The `TravelAction` automatically calls `GameTurnAction` after travel:

```ruby
# In TravelAction#run
game.advance_day!
LocationResource.seed_for_location(game, destination)

# Update all market prices
game_turn_action = GameTurnAction.new(game)
game_turn_action.run
```

## Future Enhancements

Potential additions to the price system:
- **Events** - Hurricane affects coastal cities, tech bubble affects tech_hub locations
- **Seasonal patterns** - Certain resources peak during specific day ranges
- **Rarity multipliers** - Exceptional items have more extreme swings
- **Location-specific modifiers** - Wealthy cities have higher base prices
- **Supply chain effects** - Buying lots reduces available quantity more significantly
