# Buddies System Implementation Plan

## Overview

Buddies are location-based NPCs that players can hire to automate resource trading. Each buddy is stationed at a specific location and will hold a stack of a single resource, automatically selling it when a target profit percentage is reached at that location.

## Core Concept

- **Hire Cost**: $100 per buddy
- **Location-Bound**: Each buddy stays at the location where they were hired
- **Single Resource**: Each buddy holds ONE resource type at a time
- **Auto-Sell**: When the local price reaches the target % gain, buddy sells automatically
- **Passive Income**: Buddies work while the player travels and trades elsewhere

---

## Database Schema

### `buddies` Table

```ruby
create_table :buddies do |t|
  t.references :game, null: false, foreign_key: true
  t.references :location, null: false, foreign_key: true
  t.references :resource, foreign_key: true  # nullable until assigned
  t.string :name, null: false
  t.integer :hire_cost, null: false, default: 100
  t.integer :hire_day, null: false
  t.integer :quantity, default: 0           # units of resource held
  t.decimal :purchase_price, precision: 10, scale: 2  # price paid per unit
  t.integer :target_profit_percent, default: 25       # sell when this % gain reached
  t.string :status, default: 'idle'         # idle, holding, sold
  t.decimal :last_sale_profit, precision: 10, scale: 2  # profit from last sale
  t.integer :last_sale_day                  # day of last sale
  
  t.timestamps
end

add_index :buddies, [:game_id, :location_id]
```

### Status States

| Status | Description |
|--------|-------------|
| `idle` | Buddy has no resource assignment, waiting for player to give them goods |
| `holding` | Buddy is holding resources, watching for target price |
| `sold` | Buddy sold resources, profit waiting to be collected |

---

## Models

### `Buddy` Model

```ruby
class Buddy < ApplicationRecord
  belongs_to :game
  belongs_to :location
  belongs_to :resource, optional: true
  
  enum :status, { idle: 'idle', holding: 'holding', sold: 'sold' }
  
  validates :name, presence: true
  validates :hire_cost, presence: true, numericality: { greater_than: 0 }
  validates :hire_day, presence: true
  validates :target_profit_percent, numericality: { greater_than: 0, less_than_or_equal_to: 200 }
  
  scope :at_location, ->(location) { where(location: location) }
  scope :for_game, ->(game) { where(game: game) }
  scope :with_pending_sales, -> { where(status: 'sold') }
  scope :actively_holding, -> { where(status: 'holding') }
  
  # Check if target price has been reached
  def target_price_reached?
    return false unless holding? && resource.present?
    
    game_resource = game.game_resources.find_by(resource: resource)
    return false unless game_resource
    
    current_local_price = game_resource.price_at_location(location)
    target_price = purchase_price * (1 + target_profit_percent / 100.0)
    
    current_local_price >= target_price
  end
  
  # Calculate potential profit at current prices
  def potential_profit
    return 0 unless holding? && resource.present?
    
    game_resource = game.game_resources.find_by(resource: resource)
    return 0 unless game_resource
    
    current_local_price = game_resource.price_at_location(location)
    (current_local_price - purchase_price) * quantity
  end
  
  # Execute the sale
  def execute_sale!(current_day)
    return false unless target_price_reached?
    
    game_resource = game.game_resources.find_by(resource: resource)
    sale_price = game_resource.price_at_location(location)
    profit = (sale_price - purchase_price) * quantity
    
    update!(
      status: 'sold',
      last_sale_profit: profit,
      last_sale_day: current_day
    )
    
    profit
  end
  
  # Collect sale proceeds
  def collect_proceeds!
    return 0 unless sold?
    
    total = (purchase_price * quantity) + last_sale_profit
    
    game.update!(cash: game.cash + total)
    
    # Reset buddy to idle
    update!(
      status: 'idle',
      resource: nil,
      quantity: 0,
      purchase_price: nil,
      last_sale_profit: nil,
      last_sale_day: nil
    )
    
    total
  end
end
```

### Game Model Updates

```ruby
# Add to Game model
has_many :buddies, dependent: :destroy

def buddies_at_location(location)
  buddies.at_location(location)
end

def total_buddy_holdings_value
  buddies.actively_holding.sum { |b| b.quantity * b.purchase_price }
end
```

---

## Service Actions

### `HireBuddyAction`

```ruby
class HireBuddyAction < GameAction
  HIRE_COST = 100
  
  attribute :location_id, :integer
  
  validates :location_id, presence: true
  validate :sufficient_cash
  validate :location_exists
  
  def run
    location = Location.find(location_id)
    
    buddy = game.buddies.create!(
      location: location,
      name: generate_buddy_name,
      hire_cost: HIRE_COST,
      hire_day: game.current_day,
      status: 'idle'
    )
    
    game.update!(cash: game.cash - HIRE_COST)
    
    create_log(buddy, "Hired #{buddy.name} at #{location.name} for $#{HIRE_COST}")
    
    true
  end
  
  private
  
  def sufficient_cash
    errors.add(:base, "Not enough cash to hire a buddy") if game.cash < HIRE_COST
  end
  
  def location_exists
    errors.add(:location_id, "Location not found") unless Location.exists?(location_id)
  end
  
  def generate_buddy_name
    # Fun procedural names
    BUDDY_NAMES.sample
  end
  
  BUDDY_NAMES = %w[
    Vinnie Marco Tony Sal Louie Frankie Joey Paulie
    Gino Rocco Enzo Nicky Carmine Dominic Angelo Vito
  ].freeze
end
```

### `AssignBuddyResourceAction`

```ruby
class AssignBuddyResourceAction < GameAction
  attribute :buddy_id, :integer
  attribute :resource_id, :integer
  attribute :quantity, :integer
  attribute :target_profit_percent, :integer, default: 25
  
  validates :buddy_id, :resource_id, :quantity, presence: true
  validates :quantity, numericality: { greater_than: 0 }
  validates :target_profit_percent, numericality: { greater_than: 0, less_than_or_equal_to: 200 }
  
  validate :buddy_must_be_idle
  validate :buddy_must_be_at_current_location
  validate :player_has_inventory
  
  def run
    buddy = game.buddies.find(buddy_id)
    resource = Resource.find(resource_id)
    inventory_item = game.inventory_items.by_resource(resource).fifo.first
    
    # Calculate average purchase price from inventory
    avg_price = calculate_average_price(resource)
    
    # Remove from player inventory
    deduct_from_inventory(resource, quantity)
    
    # Assign to buddy
    buddy.update!(
      resource: resource,
      quantity: quantity,
      purchase_price: avg_price,
      target_profit_percent: target_profit_percent,
      status: 'holding'
    )
    
    create_log(buddy, "Gave #{quantity}x #{resource.name} to #{buddy.name} (sell at +#{target_profit_percent}%)")
    
    true
  end
  
  private
  
  def buddy_must_be_idle
    buddy = game.buddies.find_by(id: buddy_id)
    errors.add(:base, "Buddy is already holding resources") unless buddy&.idle?
  end
  
  def buddy_must_be_at_current_location
    buddy = game.buddies.find_by(id: buddy_id)
    errors.add(:base, "Buddy is not at your current location") unless buddy&.location_id == game.current_location_id
  end
  
  def player_has_inventory
    resource = Resource.find_by(id: resource_id)
    return unless resource
    
    total = game.inventory_items.by_resource(resource).sum(:quantity)
    errors.add(:base, "Not enough #{resource.name} in inventory") if total < quantity
  end
  
  def calculate_average_price(resource)
    items = game.inventory_items.by_resource(resource)
    total_value = items.sum { |i| i.quantity * i.purchase_price }
    total_qty = items.sum(:quantity)
    total_value / total_qty
  end
  
  def deduct_from_inventory(resource, qty_to_remove)
    remaining = qty_to_remove
    
    game.inventory_items.by_resource(resource).fifo.each do |item|
      if item.quantity <= remaining
        remaining -= item.quantity
        item.destroy!
      else
        item.update!(quantity: item.quantity - remaining)
        remaining = 0
      end
      break if remaining <= 0
    end
    
    # Update game inventory size
    game.recalculate_inventory_size!
  end
end
```

### `CollectBuddySaleAction`

```ruby
class CollectBuddySaleAction < GameAction
  attribute :buddy_id, :integer
  
  validates :buddy_id, presence: true
  validate :buddy_has_sale
  validate :buddy_at_current_location
  
  def run
    buddy = game.buddies.find(buddy_id)
    total = buddy.collect_proceeds!
    
    create_log(buddy, "Collected $#{total.round(2)} from #{buddy.name}")
    
    true
  end
  
  private
  
  def buddy_has_sale
    buddy = game.buddies.find_by(id: buddy_id)
    errors.add(:base, "No sale to collect") unless buddy&.sold?
  end
  
  def buddy_at_current_location
    buddy = game.buddies.find_by(id: buddy_id)
    errors.add(:base, "Must be at buddy's location to collect") unless buddy&.location_id == game.current_location_id
  end
end
```

---

## Turn Integration

### `BuddyCheckService`

Called during `GameTurnAction` to process all buddy auto-sells:

```ruby
class BuddyCheckService
  def initialize(game)
    @game = game
  end
  
  def call
    sales = []
    
    @game.buddies.actively_holding.find_each do |buddy|
      if buddy.target_price_reached?
        profit = buddy.execute_sale!(@game.current_day)
        sales << { buddy: buddy, profit: profit }
      end
    end
    
    sales
  end
end
```

Update `GameTurnAction#run` to include:

```ruby
# After price updates, check buddy sales
buddy_sales = BuddyCheckService.new(game).call
buddy_sales.each do |sale|
  create_log(sale[:buddy], "#{sale[:buddy].name} sold #{sale[:buddy].resource.name} for $#{sale[:profit].round(2)} profit!")
end
```

---

## Controllers

### `BuddiesController`

```ruby
class BuddiesController < ApplicationController
  include GameSession
  
  def index
    @buddies = current_game.buddies.includes(:location, :resource)
    @buddies_at_location = current_game.buddies_at_location(current_game.current_location)
  end
  
  def show
    @buddy = current_game.buddies.find(params[:id])
  end
  
  def create
    action = HireBuddyAction.new(current_game, location_id: current_game.current_location_id)
    
    if action.call
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to buddies_path, notice: "Hired a new buddy!" }
      end
    else
      redirect_to buddies_path, alert: action.errors.full_messages.join(", ")
    end
  end
  
  def assign
    action = AssignBuddyResourceAction.new(current_game, assign_params)
    
    if action.call
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to buddies_path, notice: "Resource assigned!" }
      end
    else
      redirect_to buddy_path(params[:id]), alert: action.errors.full_messages.join(", ")
    end
  end
  
  def collect
    action = CollectBuddySaleAction.new(current_game, buddy_id: params[:id])
    
    if action.call
      respond_to do |format|
        format.turbo_stream
        format.html { redirect_to buddies_path, notice: "Collected sale proceeds!" }
      end
    else
      redirect_to buddies_path, alert: action.errors.full_messages.join(", ")
    end
  end
  
  private
  
  def assign_params
    params.require(:buddy).permit(:resource_id, :quantity, :target_profit_percent).merge(buddy_id: params[:id])
  end
end
```

---

## Routes

```ruby
resources :buddies, only: [:index, :show, :create] do
  member do
    post :assign
    post :collect
  end
end
```

---

## Views

### Navigation Icon (Contact Shadow Style)

Add to `_navbar.html.erb`:

```erb
<%= link_to buddies_path, class: "navbar__item" do %>
  <svg class="navbar__icon" width="24" height="24" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
    <!-- Person silhouette with shadow (buddy icon) -->
    <!-- Head -->
    <circle cx="12" cy="7" r="4" fill="currentColor"/>
    <!-- Body -->
    <path d="M12 12 C7 12 4 15 4 19 L4 20 L20 20 L20 19 C20 15 17 12 12 12 Z" fill="currentColor"/>
    <!-- Contact shadow (offset duplicate for depth) -->
    <ellipse cx="12" cy="21" rx="6" ry="1.5" fill="currentColor" opacity="0.3"/>
  </svg>
  <span class="navbar__label">Buddies</span>
  <% if buddies_with_sales_count > 0 %>
    <span class="navbar__badge"><%= buddies_with_sales_count %></span>
  <% end %>
<% end %>
```

### Index Page Structure

```
/buddies
├── Header: "Your Buddies" with hire button (if at location)
├── Section: "Buddies at [Current Location]"
│   └── Cards for each local buddy (can interact)
├── Section: "Buddies Elsewhere"
│   └── Cards for buddies at other locations (view only)
└── Empty state if no buddies
```

### Buddy Card Components

```
┌─────────────────────────────────────┐
│ [Icon] Vinnie           @ Downtown  │
│ Status: Holding                     │
│ ─────────────────────────────────── │
│ Resource: Vintage Wine (5 units)    │
│ Bought at: $120.00                  │
│ Target: +25% ($150.00)              │
│ Current: $142.50 (+18.75%)          │
│ ─────────────────────────────────── │
│ Potential Profit: $112.50           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ [Icon] Marco            @ Uptown    │
│ Status: SOLD! Collect $250.00       │
│ ─────────────────────────────────── │
│ [Collect Proceeds] button           │
└─────────────────────────────────────┘

┌─────────────────────────────────────┐
│ [Icon] Tony             @ Docks     │
│ Status: Idle - No Assignment        │
│ ─────────────────────────────────── │
│ [Assign Resource] form/button       │
└─────────────────────────────────────┘
```

---

## Implementation Phases

### Phase 1: Foundation (MVP)
1. Create migration for `buddies` table
2. Create `Buddy` model with validations and associations
3. Update `Game` model with `has_many :buddies`
4. Add routes for buddies controller
5. Create `BuddiesController` with index and create actions
6. Add navbar icon and link
7. Create basic index view

### Phase 2: Core Functionality
1. Implement `HireBuddyAction`
2. Implement `AssignBuddyResourceAction`
3. Create buddy show page with assignment form
4. Add inventory selection for assignment
5. Implement target percentage slider/input

### Phase 3: Auto-Sell System
1. Create `BuddyCheckService`
2. Integrate with `GameTurnAction`
3. Implement `CollectBuddySaleAction`
4. Add sale notifications to event log
5. Add badge count for pending collections

### Phase 4: Polish
1. Turbo Stream updates for real-time feedback
2. Toast notifications for buddy events
3. Buddy cards with status indicators
4. Price progress bars toward target
5. Buddy list sorting/filtering

---

## Helper Methods

```ruby
# ApplicationHelper or BuddiesHelper
def buddies_with_sales_count
  current_game.buddies.with_pending_sales.count
end

def buddy_status_class(buddy)
  case buddy.status
  when 'idle' then 'buddy-status--idle'
  when 'holding' then 'buddy-status--holding'
  when 'sold' then 'buddy-status--sold'
  end
end

def buddy_progress_percent(buddy)
  return 0 unless buddy.holding?
  
  current_gain = ((buddy.potential_profit / (buddy.purchase_price * buddy.quantity)) * 100).round(1)
  [(current_gain / buddy.target_profit_percent * 100), 100].min
end
```

---

## Future Enhancements (Not in MVP)

1. **Buddy Tiers**: Pay more for buddies with better abilities
   - $100 buddy: 1 resource type, basic auto-sell
   - $500 buddy: Faster selling, lower target thresholds
   - $1000 buddy: Can hold multiple resource types

2. **Buddy Skills**: Specializations based on resource tags
   - "Tech Expert" - better at technology resources
   - "Art Connoisseur" - better at antiques/collectibles

3. **Buddy Loyalty**: Long-term buddies provide bonuses

4. **Fire/Relocate**: Ability to dismiss or move buddies

5. **Buddy Events**: Random events involving buddies
   - "Your buddy found a rare item!"
   - "Your buddy got robbed!"

---

## Files to Create/Modify

### New Files
- `db/migrate/XXXXXX_create_buddies.rb`
- `app/models/buddy.rb`
- `app/controllers/buddies_controller.rb`
- `app/services/hire_buddy_action.rb`
- `app/services/assign_buddy_resource_action.rb`
- `app/services/collect_buddy_sale_action.rb`
- `app/services/buddy_check_service.rb`
- `app/views/buddies/index.html.erb`
- `app/views/buddies/show.html.erb`
- `app/views/buddies/_buddy_card.html.erb`
- `app/views/buddies/_assign_form.html.erb`
- `app/helpers/buddies_helper.rb`
- `spec/models/buddy_spec.rb`
- `spec/services/hire_buddy_action_spec.rb`
- `spec/factories/buddies.rb`

### Modified Files
- `app/models/game.rb` - Add `has_many :buddies`
- `app/views/shared/_navbar.html.erb` - Add Buddies nav item
- `app/helpers/application_helper.rb` - Add `buddies_with_sales_count`
- `app/services/game_turn_action.rb` - Integrate `BuddyCheckService`
- `config/routes.rb` - Add buddies routes
