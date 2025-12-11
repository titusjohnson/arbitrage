# Resources - Gameplay Design Document

*Inspired by the classic Drug Wars trading game*

## Overview

Resources is a turn-based trading simulation game where players travel between different locations buying and selling various goods to maximize profit within a limited timeframe. This design is based on the classic [Drug Wars](https://en.wikipedia.org/wiki/Drug_Wars_(video_game)) game originally created by John E. Dell in 1984 as a high school project, but adapted to trade generic "resources" instead of illicit substances.

## Research Summary

### Original Drug Wars (1984)

Drug Wars was a text-based DOS game that became a cultural phenomenon, spawning countless clones and adaptations across virtually every platform imaginable. The [original game](https://archive.org/details/msdos_Drug_Wars_1984) featured simple yet addictive gameplay mechanics centered around arbitrage trading in a fictional New York City setting.

### Popular Clones and Variations

The game's success led to numerous adaptations:

- **[Dope Wars (Beermat Software)](https://classicreload.com/dope-wars.html)** - Downloaded over 6.5 million times from CNET (1998-2005), one of the most popular Windows versions
- **Drug Lord 2 (2000)** - PC successor that was later ported to Android
- **[Modern web versions](https://dopewarsjs.web.app/)** - Browser-based implementations
- **Mobile versions** - Available on [iOS](https://apps.apple.com/us/app/dope-wars-weed-edition-lite/id1244428629) and Android (6+ free versions, 5 paid)
- **Platform variations** - Versions exist for TI-83 calculators, Palm OS, Newton MessagePad, Pebble smartwatches, and more
- **Social adaptations** - Zynga created an MMORPG version for Myspace
- **Grand Theft Auto: Chinatown Wars** - Included a drug trading minigame inspired by the original

For a comprehensive list of clones, see the [OSGC Drugwars clones page](https://osgameclones.com/drugwars/).

## Core Game Mechanics

### Starting Conditions

- **Initial Capital**: Player begins with $2,000
- **Inventory Capacity**: 100 units of storage space (expandable)
- **Time Limit**: 30 days to make as much profit as possible
- **Debt**: Optional loan shark system for additional starting capital (with high interest)

### Victory Conditions

- **Primary Goal**: Maximize profit by the end of 30 days
- **Perfect Score**: Reaching $50,000,000 = 100/100 score
- **Scoring Formula**: (Cash in millions × 2) = Score out of 100
  - Example: $25,000,000 = 50/100 score

### Game Loop

1. **Check Prices** - View current market prices at your location
2. **Buy Resources** - Purchase goods at current market rate
3. **Sell Resources** - Sell inventory for profit
4. **Travel** - Move to a different location (costs 1 day)
5. **Repeat** - Continue until 30 days expire

### Locations

Multiple locations with fluctuating prices for different resources. In our version, instead of New York boroughs, we could use:
- Different cities
- Different markets
- Different regions
- Different districts

### Resources to Trade

Instead of the original 6 drugs (Cocaine, Heroin, Acid, Weed, Speed, Ludes), we'll use generic valuable goods:
- Electronics
- Luxury Goods
- Raw Materials
- Food & Produce
- Textiles
- Collectibles
- Rare Artifacts
- Tech Components
- Art & Antiques
- Precious Metals

Each resource has:
- **Base Price Range** - Typical low/high values
- **Price Volatility** - How much prices can fluctuate
- **Volume** - How much inventory space each unit takes

## Strategic Elements

### Market Dynamics

**Price Fluctuations** ([strategy tips](https://drugwars.games/how-to-play)):
- Prices change dramatically between locations
- Special events can cause 10x price spikes
- Buy low in one location, sell high in another
- High-value items like rare artifacts can drop to 10% of normal price, then spike to 500%

**Optimal Strategy** ([detailed guide](https://gamefaqs.gamespot.com/pc/562935-dope-wars/faqs/7372)):
- Wait for rare resources to hit rock-bottom prices
- Buy maximum capacity
- Travel until finding extreme high prices
- Sell entire inventory for massive profit

### Random Events

**Positive Events**:
- Price spikes ("Collectors convention in town! Art prices soaring!")
- Found items ("You discovered abandoned storage!")
- Special deals ("Merchant offers bulk discount!")

**Negative Events**:
- Market crashes ("Economic downturn affects luxury goods!")
- Theft attempts (lose inventory or cash)
- Inspections (potential loss of contraband items)

**Special Encounters**:
- Rival traders (combat or flee options)
- Merchant offers (upgrade opportunities)
- Authorities (risk vs. reward scenarios)

### Upgrades & Equipment

**Inventory Expansion**:
- Purchase additional storage capacity
- Rent warehouse space in locations
- Acquire better transportation

**Protection**:
- Security systems (reduce theft risk)
- Insurance policies (protect investments)
- Bodyguards (defend against rivals)

**Financial Tools**:
- **Banking System** ([optimal play](https://www.neoseeker.com/drug-wars/faqs/100841-a.html)): 
  - Deposit money for safety
  - Earn high interest rates
  - Protect cash from theft/seizure
  - Often optimal to leave most money in bank

- **Loan Sharks**:
  - Borrow capital for bigger trades
  - High interest rates
  - Must repay or face penalties

### Risk Management

**Combat System** (if included):
- Encounter hostile traders or authorities
- Options: Run, Fight, Negotiate, Pay Bribe
- Requires security equipment to fight
- Win rewards, lose consequences (health/inventory loss)
- 10 damage points = game over

**Health System**:
- Take damage from failed encounters
- Visit clinics to restore health
- Upgrade max health capacity
- Death = game over

## Modern Enhancements

Based on analysis of [successful modern versions](https://medium.com/@plewis67/a-better-version-of-dope-wars-9b7efc105c00):

### Quality of Life Improvements
- Visual price charts showing trends
- Inventory management interface
- Quick-buy/quick-sell at market rate
- Travel time indicators
- Profit/loss tracking

### Additional Features
- Leaderboards (high scores)
- Multiple difficulty modes
- Achievement system
- Story mode with missions
- Tutorial for new players

### Web-Specific Features
- Responsive design for mobile/desktop
- Local storage for save games
- Real-time price updates
- Animated transitions
- Sound effects (optional)

## Adaptation for "Resources"

### Thematic Changes

Instead of the criminal underground theme, Resources will use a legitimate merchant/trader theme:
- You're an entrepreneur in a bustling trade economy
- Travel between cities/markets buying and selling goods
- Build your trading empire through smart business decisions
- No illegal activities, just shrewd capitalism

### Tone & Presentation

- **Mid-2000s web aesthetic** (matching our current design)
- Clean, functional interface with tactile buttons
- Simple, readable tables for price displays
- Classic web game feel with modern conveniences
- Emphasis on strategy over shock value

### Gameplay Balance

Start with proven mechanics from the original:
1. 30-day time limit
2. Multiple locations (6-8 cities)
3. 10-12 different tradeable resources
4. Random events and price fluctuations
5. Loan and banking systems
6. Inventory management

Then iterate based on playtesting and user feedback.

## Technical Implementation Notes

### Data Model (Initial Thoughts)

- **Player**: cash, inventory, location, day, health, upgrades
- **Location**: name, resources with current prices
- **Resource**: name, base_price_range, volatility, space_cost
- **Transaction**: buy/sell history for statistics
- **Event**: random occurrences with effects
- **Equipment**: storage upgrades, security, etc.

### Game State Management

- Store game state in session/database
- Calculate prices dynamically on each turn
- Trigger random events based on probability
- Track statistics for end-game scoring
- Support save/load functionality

## References & Sources

### Core Research
- [Drug Wars (Wikipedia)](https://en.wikipedia.org/wiki/Drug_Wars_(video_game))
- [Original DOS version (Internet Archive)](https://archive.org/details/msdos_Drug_Wars_1984)
- [How to Play Drug Wars - Complete Guide](https://drugwars.games/how-to-play)

### Strategy Guides
- [Dope Wars FAQ/Strategy Guide](https://www.neoseeker.com/drug-wars/faqs/100841-a.html)
- [Dope Wars Tips & Tricks](http://androidplazza.com/dope-wars-tips-tricks/)
- [GameFAQs Hints and Tips](https://gamefaqs.gamespot.com/pc/562935-dope-wars/faqs/7372)

### Clones & Variations
- [Drugwars Clones List (OSGC)](https://osgameclones.com/drugwars/)
- [Modern Web Version](https://dopewarsjs.web.app/)
- [Classic Reload - Dope Wars](https://classicreload.com/dope-wars.html)
- [A Better Version of Dope Wars (Medium)](https://medium.com/@plewis67/a-better-version-of-dope-wars-9b7efc105c00)

### Platform Information
- [BBS Wiki - Drugwars](https://breakintochat.com/wiki/Drugwars)
- [iOS App Store Version](https://apps.apple.com/us/app/dope-wars-weed-edition-lite/id1244428629)

## Next Steps

1. Review and refine gameplay mechanics
2. Design database schema for game entities
3. Create wireframes for game interface
4. Implement core trading loop
5. Add random events and price fluctuations
6. Balance difficulty and progression
7. Playtesting and iteration

---

*This design document will evolve as we build and test the game. Feedback and ideas welcome!*
