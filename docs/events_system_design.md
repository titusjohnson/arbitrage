# Events System Design Document

## Overview

The Events system introduces random, dynamic market conditions that affect resource prices and location availability throughout the 30-day game. Events are triggered randomly or on specific days, creating strategic opportunities and challenges for players.

## Core Concept

Events use a **tag-based modifier system** to affect multiple resources and locations simultaneously. Rather than hardcoding specific items, events target tags (like "food", "fragile", "port_city") and apply multipliers or adjustments to matching resources and locations.

## Database Schema

### Events Table

```ruby
create_table :events do |t|
  t.string :name, null: false
  t.text :description
  t.integer :day_start         # When the event begins (1-30)
  t.integer :duration          # How many days it lasts (1-7)
  t.boolean :active, default: false
  
  # JSON fields for tag-based effects
  t.jsonb :resource_effects, default: {}
  t.jsonb :location_effects, default: {}
  
  # Metadata
  t.string :event_type         # "market", "weather", "political", "cultural"
  t.integer :severity          # 1-5 scale of impact magnitude
  t.string :rarity             # "common", "uncommon", "rare", "ultra_rare", "exceptional"
  
  t.timestamps
end
```

### GameEvents Join Table

Since events are global occurrences but affect individual games differently:

```ruby
create_table :game_events do |t|
  t.references :game, null: false, foreign_key: true
  t.references :event, null: false, foreign_key: true
  t.integer :day_triggered      # Which game day the event started
  t.integer :days_remaining     # Countdown for active events
  t.boolean :seen, default: false
  
  t.timestamps
end
```

## JSON Schema for Effects

### Resource Effects Structure

```json
{
  "price_modifiers": [
    {
      "tags": ["food", "perishable"],
      "match": "all",
      "multiplier": 0.5,
      "description": "Perishable foods half price"
    },
    {
      "tags": ["alcohol"],
      "match": "any",
      "multiplier": 2.0,
      "description": "Alcohol prices doubled"
    }
  ],
  "volatility_modifiers": [
    {
      "tags": ["fragile"],
      "match": "any",
      "adjustment": 20,
      "description": "Fragile items +20% more volatile"
    }
  ],
  "availability_modifiers": [
    {
      "tags": ["european_origin"],
      "match": "any",
      "multiplier": 0.3,
      "description": "European goods 70% less available"
    }
  ]
}
```

### Location Effects Structure

Uses scoped tags to separately target location and resource tags:

```json
{
  "quantity_modifiers": [
    {
      "scoped_tags": {
        "location": ["port_city"],
        "resource": ["food", "perishable"]
      },
      "match": "all",
      "multiplier": 0.2,
      "description": "Perishable food in ports reduced by 80%"
    }
  ],
  "access_restrictions": [
    {
      "scoped_tags": {
        "location": ["coastal"]
      },
      "blocked": true,
      "description": "Coastal cities inaccessible"
    }
  ],
  "price_modifiers": [
    {
      "scoped_tags": {
        "location": ["tech_hub"],
        "resource": ["technology"]
      },
      "match": "all",
      "multiplier": 0.7,
      "description": "Tech goods 30% cheaper in tech hubs"
    }
  ]
}
```

## Three Example Events

### Example 1: Hurricane Havoc

**Event Type:** Weather  
**Severity:** 4  
**Rarity:** Rare  
**Duration:** 3-5 days

**Name:** "Hurricane Havoc"

**Description:** "Category 4 hurricane batters the eastern seaboard. Coastal cities shut down, ports close, and shipments are delayed indefinitely. Stock up on essentials before the storm passes."

**Affected Tags:**
- **Location Tags:** `coastal`, `port_city`, `northeastern`
- **Resource Tags:** `perishable`, `food`, `fragile`, `bulky`

**Resource Effects:**
```json
{
  "price_modifiers": [
    {
      "tags": ["food", "perishable"],
      "match": "all",
      "multiplier": 2.5,
      "description": "Perishable food prices spike due to supply disruption"
    },
    {
      "tags": ["fragile"],
      "match": "any",
      "multiplier": 1.8,
      "description": "Fragile items more expensive (shipping risk)"
    }
  ],
  "availability_modifiers": [
    {
      "tags": ["bulky"],
      "match": "any",
      "multiplier": 0.3,
      "description": "Bulky items 70% less available (shipping delays)"
    }
  ],
  "volatility_modifiers": [
    {
      "tags": ["perishable"],
      "match": "any",
      "adjustment": 30,
      "description": "Perishable goods extremely volatile"
    }
  ]
}
```

**Location Effects:**
```json
{
  "access_restrictions": [
    {
      "scoped_tags": {
        "location": ["coastal", "northeastern"]
      },
      "match": "all",
      "blocked": true,
      "description": "Northeastern coastal cities evacuated and inaccessible"
    }
  ],
  "quantity_modifiers": [
    {
      "scoped_tags": {
        "location": ["port_city"],
        "resource": ["food"]
      },
      "match": "any",
      "multiplier": 0.1,
      "description": "Food supplies in port cities critically low"
    }
  ]
}
```

**Strategic Impact:**
- Players in coastal northeastern cities need to evacuate or stock up
- Resources get trapped in inaccessible locations
- Inland cities become premium trading hubs
- Perishable goods become high-risk, high-reward trades
- Fragile items dangerous to transport

---

### Example 2: Tech Bubble Burst

**Event Type:** Market  
**Severity:** 3  
**Rarity:** Uncommon  
**Duration:** 5-7 days

**Name:** "Dot-Com Déjà Vu"

**Description:** "Major tech companies announce mass layoffs. Stock markets tumble. Silicon Valley panics. Tech gadgets flood the market as startups liquidate. Luxury spending plummets while investors flee to gold."

**Affected Tags:**
- **Location Tags:** `tech_hub`, `wealthy`, `financial_center`
- **Resource Tags:** `technology`, `luxury_fashion`, `precious_metal`, `investment`

**Resource Effects:**
```json
{
  "price_modifiers": [
    {
      "tags": ["technology"],
      "match": "any",
      "multiplier": 0.4,
      "description": "Tech liquidation sales - 60% off"
    },
    {
      "tags": ["luxury_fashion"],
      "match": "any",
      "multiplier": 0.6,
      "description": "Luxury goods discounted as wealthy panic-sell"
    },
    {
      "tags": ["precious_metal"],
      "match": "any",
      "multiplier": 1.6,
      "description": "Gold and silver surge as safe havens"
    },
    {
      "tags": ["investment", "collectible"],
      "match": "all",
      "multiplier": 1.4,
      "description": "Collectible investments gain value during uncertainty"
    }
  ],
  "availability_modifiers": [
    {
      "tags": ["technology"],
      "match": "any",
      "multiplier": 2.5,
      "description": "Tech inventory floods market"
    }
  ]
}
```

**Location Effects:**
```json
{
  "quantity_modifiers": [
    {
      "scoped_tags": {
        "location": ["tech_hub"],
        "resource": ["technology"]
      },
      "match": "any",
      "multiplier": 3.0,
      "description": "Tech hubs overwhelmed with liquidated inventory"
    },
    {
      "scoped_tags": {
        "location": ["tech_hub"],
        "resource": ["luxury_fashion"]
      },
      "match": "any",
      "multiplier": 2.0,
      "description": "Ex-tech workers selling their Hermès bags"
    },
    {
      "scoped_tags": {
        "location": ["financial_center"],
        "resource": ["precious_metal"]
      },
      "match": "any",
      "multiplier": 0.5,
      "description": "Financial centers buying up all precious metals"
    }
  ],
  "price_modifiers": [
    {
      "scoped_tags": {
        "location": ["tech_hub"],
        "resource": ["technology"]
      },
      "match": "any",
      "multiplier": 0.3,
      "description": "Rock-bottom prices in tech hubs"
    }
  ]
}
```

**Strategic Impact:**
- Buy cheap tech in San Francisco, Seattle, Austin, Boston
- Sell luxury goods before prices crash further
- Precious metals become hot commodities
- Tech hubs transform from expensive to buyer's markets
- Financial centers (NYC, Chicago) see gold/silver shortages

---

### Example 3: Prohibition Flashback

**Event Type:** Political  
**Severity:** 2  
**Rarity:** Uncommon  
**Duration:** 4-6 days

**Name:** "The Great Beverage Ban"

**Description:** "Federal law enforcement cracks down on alcohol distribution in a multi-state sting operation. Bars close, shipments confiscated, prices skyrocket. Meanwhile, coffee and tea merchants quietly celebrate their good fortune."

**Affected Tags:**
- **Location Tags:** `entertainment`, `tourist_destination`, `wealthy`
- **Resource Tags:** `alcohol`, `food` (specifically beverages), `consumable`

**Resource Effects:**
```json
{
  "price_modifiers": [
    {
      "tags": ["alcohol"],
      "match": "any",
      "multiplier": 4.0,
      "description": "Alcohol prices quadruple due to crackdown"
    },
    {
      "tags": ["food", "consumable"],
      "match": "all",
      "multiplier": 1.3,
      "description": "Alternative beverages see increased demand"
    }
  ],
  "availability_modifiers": [
    {
      "tags": ["alcohol"],
      "match": "any",
      "multiplier": 0.15,
      "description": "Alcohol supplies vanish from legitimate markets"
    }
  ],
  "volatility_modifiers": [
    {
      "tags": ["alcohol"],
      "match": "any",
      "adjustment": 50,
      "description": "Alcohol prices wildly unpredictable"
    }
  ]
}
```

**Location Effects:**
```json
{
  "quantity_modifiers": [
    {
      "scoped_tags": {
        "location": ["entertainment", "tourist_destination"],
        "resource": ["alcohol"]
      },
      "match": "any",
      "multiplier": 0.05,
      "description": "Entertainment districts cleared of alcohol"
    },
    {
      "scoped_tags": {
        "location": ["wealthy"],
        "resource": ["alcohol"]
      },
      "match": "any",
      "multiplier": 0.4,
      "description": "Wealthy neighborhoods still have 'private collections'"
    }
  ],
  "price_modifiers": [
    {
      "scoped_tags": {
        "location": ["entertainment"],
        "resource": ["alcohol"]
      },
      "match": "any",
      "multiplier": 5.0,
      "description": "Black market prices in entertainment districts"
    },
    {
      "scoped_tags": {
        "location": ["tourist_destination"],
        "resource": ["food", "consumable"]
      },
      "match": "all",
      "multiplier": 1.5,
      "description": "Tourists turn to premium coffee and tea"
    }
  ]
}
```

**Strategic Impact:**
- Alcohol becomes incredibly profitable but risky to trade
- Las Vegas, Nashville, New Orleans see alcohol shortages
- NYC, LA, DC (wealthy areas) still have limited expensive stock
- Premium coffee, tea, chocolate see demand surge
- Entertainment cities struggle without alcohol sales
- Players holding alcohol inventory strike gold

---

## Implementation Considerations

### Tag Matching Logic

**Match Types:**
- `any`: Resource/location must have AT LEAST ONE of the specified tags
- `all`: Resource/location must have ALL specified tags
- This allows precise targeting:
  - `["food", "perishable"], match: "all"` → Only items that are BOTH food AND perishable
  - `["alcohol"], match: "any"` → Any item tagged with alcohol

### Effect Priority & Stacking

1. **Location-specific modifiers** override global resource modifiers
2. **Multiple events** can stack their effects (multiplicative)
3. **Access restrictions** trump all other modifiers (can't trade if location blocked)

Example:
- Global event: +50% to all food
- Location event: -30% to food in port cities
- Final result: Food in port cities is +5% (1.5 × 0.7 = 1.05)

### Calculation Flow

When calculating a resource's price/availability at a location:

1. **Get base resource stats** (base_price, volatility, etc.)
2. **Apply active global resource modifiers** for matching tags
3. **Apply active location-specific modifiers** for matching location + resource tag combos
4. **Check access restrictions** (is location blocked?)
5. **Calculate final values** with all multipliers

## Event Rarity System

Similar to Resources, Events have a rarity classification that determines their frequency and impact. With 50 total unique events in the pool, rarity controls how often players encounter specific events during a 30-day game.

### Rarity Tiers and Distribution

**Total Events Pool: 50 events**

| Rarity | Count | Trigger Chance per Day | Avg per Game | Severity Range | Duration Range |
|--------|-------|------------------------|--------------|----------------|----------------|
| **Common** | 20 events (40%) | 15-25% | 8-12 events | 1-2 | 1-3 days |
| **Uncommon** | 15 events (30%) | 8-15% | 4-6 events | 2-3 | 2-4 days |
| **Rare** | 10 events (20%) | 3-8% | 1-3 events | 3-4 | 3-5 days |
| **Ultra Rare** | 4 events (8%) | 1-3% | 0-1 events | 4-5 | 4-6 days |
| **Exceptional** | 1 event (2%) | 0.5-1% | 0-1 events | 5 | 5-7 days |

### Rarity Characteristics

**Common Events (20 total)**
- Minor market fluctuations and local conditions
- Low severity (1-2), minimal disruption
- Short duration (1-3 days)
- Affect 1-2 resource tags or 1-2 location tags
- Examples: "Coffee Shortage", "Rainy Weekend Sales", "Local Art Fair"

**Uncommon Events (15 total)**
- Notable market shifts and regional impacts
- Medium severity (2-3), moderate disruption
- Medium duration (2-4 days)
- Affect 2-3 resource tags or 2-4 location tags
- Examples: "Tech Bubble Burst", "Prohibition Flashback", "Vintage Boom"

**Rare Events (10 total)**
- Major economic or environmental disruptions
- High severity (3-4), significant disruption
- Longer duration (3-5 days)
- Affect 3-5 resource tags or entire regions
- Examples: "Hurricane Havoc", "Banking Crisis", "Counterfeit Crackdown"

**Ultra Rare Events (4 total)**
- Catastrophic events with game-changing impact
- Very high severity (4-5), massive disruption
- Extended duration (4-6 days)
- Affect multiple tag categories or entire coasts
- Examples: "Stock Market Crash", "Pandemic Lockdown", "Federal Reserve Chaos"

**Exceptional Event (1 total)**
- Once-in-a-lifetime mega-event
- Maximum severity (5), game-defining impact
- Maximum duration (5-7 days)
- Affects entire game economy, multiple systems
- Example: "The Great Reset" (complete economic upheaval)

### Event Triggering System

**Trigger Mechanisms:**
- **Random Pool**: Each day, game selects from available events weighted by rarity
- **Cooldown System**: Events can't repeat for X days after occurring
- **Exclusivity**: Some events prevent others from triggering (no duplicate weather events)
- **Chain Triggers**: Rare+ events can trigger related common/uncommon events

**Daily Trigger Logic:**
```ruby
# Probability that ANY event triggers on a given day
base_event_chance = 40% # ~12 events over 30 days

# When an event triggers, weighted selection from available events:
- Common: 60% chance (most likely)
- Uncommon: 25% chance
- Rare: 12% chance
- Ultra Rare: 2.5% chance
- Exceptional: 0.5% chance
```

**Expected Event Distribution per 30-Day Game:**
- Total events: 10-15 events per game
- Common: 6-8 events
- Uncommon: 3-5 events
- Rare: 1-2 events
- Ultra Rare: 0-1 events
- Exceptional: 0-1 events (very rare to see)

### Rarity Impact on Gameplay

**Common Events:**
- Create daily trading opportunities
- Minor price swings (±20-40%)
- Keep market dynamic without overwhelming
- Low risk, low reward decisions

**Uncommon Events:**
- Force tactical adaptation
- Moderate price swings (±40-100%)
- Create clear winners/losers
- Medium risk, medium reward

**Rare Events:**
- Strategic game-changers
- Major price swings (±100-300%)
- Block locations or create scarcity
- High risk, high reward opportunities

**Ultra Rare Events:**
- Memorable moments that define a playthrough
- Extreme price swings (±300-500%)
- Fundamental market restructuring
- Make-or-break player decisions

**Exceptional Event:**
- The "story moment" of the game
- Unprecedented chaos and opportunity
- Legendary plays and legendary failures
- Players share stories about this event

### UI/UX Considerations

**Event Notifications:**
- Breaking news style alert when event triggers
- Event timeline showing active/upcoming events
- Location view shows if location is affected
- Resource view shows price modifiers with explanation

**Visual Indicators:**
- 🔴 Blocked location (inaccessible)
- 📈 Price increase (green arrow)
- 📉 Price decrease (red arrow)
- ⚡ High volatility warning
- 📦 Limited availability indicator

## Future Enhancements

1. **Player-Triggered Events**: Player choices/actions can trigger events
2. **Event Chains**: Hurricane → Food Shortage → Price Controls
3. **Regional Events**: Only affect specific geographic areas (x/y coordinates)
4. **Persistent Effects**: Some events have lasting consequences
5. **Event Predictions**: Players can see hints/warnings of upcoming events
6. **Insurance System**: Players can buy insurance against event impacts

## Technical Notes

### Database Queries

Finding affected resources and locations using scoped tags:
```ruby
# Resources matching ANY specified tags
Resource.tagged_with(names: ['food', 'perishable'], match: :any)

# Resources matching ALL specified tags
Resource.tagged_with(names: ['food', 'perishable'], match: :all)

# Locations matching specific tags
Location.tagged_with(names: ['port_city', 'coastal'], match: :any)

# Using scoped tags to query both location and resource tags
# Find all tech resources in tech hub locations
Location.tagged_with(location: ['tech_hub']).joins(:resources)
  .merge(Resource.tagged_with(resource: ['technology']))
```

### Price Calculation Example

```ruby
def calculate_event_modified_price(resource, location)
  base_price = resource.current_base_price
  multiplier = 1.0
  
  # Apply global resource effects
  active_events.each do |event|
    event.resource_effects['price_modifiers']&.each do |modifier|
      if resource.matches_tags?(modifier['tags'], modifier['match'])
        multiplier *= modifier['multiplier']
      end
    end
  end
  
  # Apply location-specific effects using scoped tags
  active_events.each do |event|
    event.location_effects['price_modifiers']&.each do |modifier|
      scoped_tags = modifier['scoped_tags']
      location_match = scoped_tags['location'].nil? || 
                       location.matches_tags?(scoped_tags['location'], modifier['match'])
      resource_match = scoped_tags['resource'].nil? || 
                       resource.matches_tags?(scoped_tags['resource'], modifier['match'])
      
      if location_match && resource_match
        multiplier *= modifier['multiplier']
      end
    end
  end
  
  (base_price * multiplier).round
end
```

## Summary

The Events system transforms the game from static trading to dynamic market simulation. By using tag-based modifiers, events can affect dozens of resources and locations with simple JSON configuration, creating emergent gameplay without hardcoding specific item interactions.

**Key Benefits:**
- **Scalable**: Adding new events doesn't require code changes
- **Flexible**: Events can target precise combinations of attributes
- **Emergent**: Multiple events create complex market conditions
- **Strategic**: Players must adapt to changing conditions
- **Replayable**: Random events ensure each game is different

**Core Philosophy:**
Events should create **meaningful decisions**, not just random chaos. Every event opens opportunities for prepared players while punishing those caught off-guard.
