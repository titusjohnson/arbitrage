# Turn-Based Actions - Resources Game

*Planning document for player actions and turn flow*

## Turn Structure

Each turn represents one day in the 30-day game. The player takes actions at their current location, then optionally travels to a new location (which consumes the turn and advances the day counter).

## Core Player Actions

### 1. Market Actions (Don't Consume Turn)

These actions happen at the current location and don't advance the day:

#### **View Market Prices**
- See current buy/sell prices for all resources at this location
- View your current inventory
- Check available storage space
- Compare to prices at other known locations (if we implement price memory)

#### **Buy Resources**
- Select resource type
- Specify quantity (limited by cash and inventory space)
- Confirm purchase at current market price
- Updates: cash decreases, inventory increases

#### **Sell Resources**
- Select resource from inventory
- Specify quantity to sell
- Confirm sale at current market price
- Updates: inventory decreases, cash increases

#### **View Status**
- Current cash on hand
- Bank balance (if implemented)
- Inventory (what you're carrying)
- Current location
- Current day (X/30)
- Health status (if implemented)
- Debt status (if loans implemented)

### 2. Location-Based Actions (Don't Consume Turn)

Actions available at the current location:

#### **Visit Bank**
- Deposit cash (move money from pocket to bank)
- Withdraw cash (move money from bank to pocket)
- Check balance
- View accumulated interest
- Take out loan (if loan system implemented)
- Make loan payment (if you have debt)

#### **Visit Warehouse/Storage**
- Store inventory items (if local storage implemented)
- Retrieve stored items
- Upgrade storage capacity (purchase)
- View what's stored in this location

#### **Visit Market/Merchant**
- Purchase inventory upgrades (more carrying capacity)
- Buy equipment/upgrades
  - Better transport (more capacity)
  - Security systems (reduce theft risk)
  - Insurance (protect from losses)
- Sell equipment (if we allow this)

#### **Visit Clinic/Hospital** (if health system implemented)
- Heal damage
- Purchase health upgrades
- Buy medical supplies

#### **Visit Black Market/Special Merchant** (optional feature)
- Access to rare/special resources
- Different price dynamics
- Higher risk/reward trades

### 3. Travel Actions (CONSUME TURN)

**Travel to Different Location**
- Select destination from available locations
- Confirm travel (this advances the day)
- Random event may trigger during travel
- Arrive at new location with updated market prices

**Travel triggers:**
- Day counter increments (X/30)
- All market prices recalculate
- Random event check (theft, finding items, special offers, etc.)
- Loan interest accrues (if applicable)
- Bank interest accrues (if applicable)

### 4. Encounter Actions (Triggered by Events)

When random encounters occur, player chooses response:

#### **Rival Trader Encounter**
- **Fight** - Requires security/weapons, risk health for reward
- **Run** - Escape attempt, may lose items or take damage
- **Negotiate** - Pay bribe or make deal
- **Ignore** - Continue, accept consequences

#### **Authority Encounter** (if implemented)
- **Comply** - Submit to inspection, possible fines/losses
- **Bribe** - Pay to avoid trouble
- **Run** - Escape attempt, higher risk
- **Fight** - Extreme risk option

#### **Merchant Offer**
- **Accept** - Take the special deal
- **Decline** - Pass on the opportunity
- **Negotiate** - Try for better terms (risk losing deal)

#### **Found Items/Windfall**
- **Take** - Accept found resources/cash
- **Ignore** - Leave it (why would you? but option exists)
- **Investigate** - Learn more (might reveal trap/opportunity)

### 5. Administrative Actions (Don't Consume Turn)

#### **Save Game**
- Save current progress to database/session
- Multiple save slots (optional)

#### **View Statistics**
- Total profit/loss
- Transactions history
- Locations visited
- Resources traded
- Best deals made

#### **View Leaderboard** (if implemented)
- High scores
- Your ranking
- Friend comparisons

#### **Help/Tutorial**
- View game rules
- See resource descriptions
- Learn about mechanics

#### **Settings**
- Sound on/off
- Notifications
- Display preferences

### 6. End-Turn Summary Actions

After traveling (when turn ends):

#### **Review Turn Results**
- See what changed
- View random events that occurred
- Check updated prices at new location
- Review profit/loss for the turn

#### **Advance to Next Turn**
- Confirm ready to continue
- Proceed to next day

---

## Turn Flow Diagram

```
START OF TURN
    ↓
[Current Location View]
    ↓
Player can perform unlimited non-turn-consuming actions:
    - View prices
    - Buy resources
    - Sell resources
    - Visit bank
    - Visit warehouse
    - Visit merchants
    - Check status
    - View stats
    ↓
Player decides to TRAVEL
    ↓
[Select Destination]
    ↓
TRAVEL OCCURS (Turn Consumed)
    ↓
[Random Event Check]
    - If event: Player handles encounter
    - If no event: Continue
    ↓
[Arrive at New Location]
    - Day counter increments
    - Prices recalculate
    - Interest/debt updates
    ↓
[New Turn Begins]
    ↓
Repeat until Day 30
    ↓
[GAME OVER - Final Score]
```

---

## Action Priority & Categorization

### Phase 1 (MVP - Minimum Viable Product)
Essential actions to make the game playable:
- ✅ View market prices
- ✅ Buy resources
- ✅ Sell resources
- ✅ View status/inventory
- ✅ Travel to location
- ✅ End game scoring

### Phase 2 (Enhanced Gameplay)
Actions that add strategic depth:
- Banking system (deposit/withdraw)
- Warehouse storage
- Random events (simple)
- Basic encounter choices
- Price history/trends

### Phase 3 (Advanced Features)
Actions that add complexity:
- Loan system
- Health/combat system
- Equipment upgrades
- Special merchants
- Complex encounters
- Achievement system

### Phase 4 (Polish & Social)
Nice-to-have features:
- Leaderboards
- Statistics tracking
- Multiple save slots
- Tutorial system
- Sound effects
- Animations

---

## Key Questions to Resolve

1. **Turn consumption**: Should banking/warehouse visits consume a turn? 
   - Recommendation: No, only travel consumes turns

2. **Batch actions**: Can players buy multiple different resources in one turn?
   - Recommendation: Yes, unlimited actions until travel

3. **Event frequency**: How often should random events occur?
   - Recommendation: 20-30% chance on travel, scalable by difficulty

4. **Undo/confirm**: Should purchases have confirmation dialogs?
   - Recommendation: Yes for large transactions, optional for small

5. **Auto-save**: Save after every action or only on travel?
   - Recommendation: Auto-save after every turn (travel)

6. **Price visibility**: Can players see prices at other locations before traveling?
   - Recommendation: Phase 1 = No, Phase 2+ = Optional upgrade/feature

7. **Inventory limits**: Hard cap or pay-per-unit for excess?
   - Recommendation: Hard cap, upgradeable through merchants

---

## UI Considerations for Actions

### Main Game Screen Layout
```
+----------------------------------+
| Day: 5/30  |  Cash: $15,000     |
| Location: Metro City             |
+----------------------------------+
| [Market Prices]  [Your Inventory]|
| - Electronics   $500   [ Buy ]   |
| - Luxury Goods  $300   [ Sell]   |
| ...                              |
+----------------------------------+
| [Bank] [Warehouse] [Merchant]    |
| [Travel] [Stats] [Save]          |
+----------------------------------+
```

### Action Buttons Style
- Primary actions: Blue buttons (Buy, Sell, Travel)
- Secondary actions: Gray buttons (View, Check, Stats)
- Dangerous actions: Red buttons (Fight, Risky choices)
- Confirm actions: Green buttons (Confirm, Accept)

### Feedback & Validation
- Show error messages for invalid actions (not enough cash, full inventory)
- Confirm dialogs for irreversible actions (traveling, fighting)
- Success messages for completed actions (bought, sold, saved)
- Warning messages for risky actions (low cash, low health)

---

## Next Steps

1. Choose Phase 1 (MVP) actions to implement first
2. Design database schema for game state
3. Create wireframes for main game screen
4. Plan API endpoints for each action type
5. Implement turn logic and state transitions
6. Build UI components for action buttons/forms

---

*This document will evolve as we design and implement the game mechanics.*
