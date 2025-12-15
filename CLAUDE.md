# Resources - Rails 8 Application

## Project Overview

Resources is a Rails 8 application built with modern conventions and best practices. It's a resource management game where players navigate through 30 days, making strategic decisions about resources and trading.

## Technology Stack

- **Framework**: Rails 8.0.4
- **Ruby**: 3.3.4
- **Database**: SQLite3
- **Frontend**: 
  - Hotwire (Turbo & Stimulus)
  - ImportMap for JavaScript
  - Sass for stylesheets (no CSS framework)
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Deployment**: Kamal 2.9.0

## Key Features

### Anonymous Game Sessions
The application uses completely anonymous gameplay. No user accounts or authentication required:
- Each game is identified by a unique `restore_key` stored in the session
- When a user visits the site, they either resume their current game or start a new one
- Games are automatically created and tracked via session cookies
- The `GameSession` concern handles game loading and creation

### Database Structure
- **Games Table**: Stores individual game instances with restore_key for session-based identification
- **Resources Table**: Stores resource types available in the game (70 total resources)
- **Tagging System**: Uses gutentag gem for flexible resource categorization

### Resource Tagging System
Resources are tagged with an 18-tag system to enable event-based gameplay modifiers:

#### Material/Category Tags (9 tags)
- `precious_metal` (4 resources) - Gold, silver, rhodium
- `gemstone` (7 resources) - Diamonds, jade, rare minerals
- `food` (14 resources) - Perishable consumables, spices, delicacies
- `alcohol` (4 resources) - Wine, whisky, champagne
- `collectible` (21 resources) - Cards, comics, stamps, coins
- `timepiece` (6 resources) - Watches and clocks
- `luxury_fashion` (7 resources) - Bags, sunglasses, sneakers, clothing
- `antique` (28 resources) - Historical items, old books, vintage items
- `technology` (3 resources) - Electronics, cameras, video games

#### Attribute Tags (6 tags)
- `perishable` (14 resources) - Items that spoil/degrade quickly
- `fragile` (31 resources) - Delicate items requiring careful transport
- `bulky` (7 resources) - Large inventory size items
- `compact` (36 resources) - Small inventory size items
- `investment` (29 resources) - Store-of-value items
- `consumable` (22 resources) - Items meant to be used/consumed

#### Geographic/Cultural Tags (3 tags)
- `asian_origin` (10 resources) - Items from Asia
- `european_origin` (26 resources) - Items from Europe
- `artisan` (21 resources) - Handcrafted specialty items

**Querying Tagged Resources:**
```ruby
# Single tag
Resource.tagged_with(names: ['food'])

# Multiple tags with ANY match
Resource.tagged_with(names: ['perishable', 'food'], match: :any)

# Multiple tags with ALL match
Resource.tagged_with(names: ['investment', 'compact'], match: :all)
```

## Development Setup

### Prerequisites
- Ruby 3.3.4
- Rails 8.0.4
- SQLite3
- Homebrew (for macOS dependencies)

### Getting Started
```bash
# Install dependencies
bundle install

# Setup database
bin/rails db:create db:migrate

# Seed the database (creates game resources)
bin/rails db:seed

# Start the development server
bin/dev
```

## Project Structure

### Models
- `app/models/game.rb` - Game instance model with session-based identification
- `app/models/resource.rb` - Resource types available in the game

### Controllers
- `app/controllers/application_controller.rb` - Base controller with game session management
- `app/controllers/concerns/game_session.rb` - Anonymous game session concern

### Views
- `app/views/pages/` - Static pages

## Game Mechanics

### Game Flow
1. User lands on the site
2. System checks for existing game via session `restore_key`
3. If found, resume that game; otherwise create a new game
4. Game lasts 30 days with various resources to manage
5. Game ends with a final score based on net worth

### Game Model
The `Game` model tracks:
- Current day (1-30)
- Financial state: cash, bank balance, debt
- Health and inventory capacity
- Statistics: purchases, sales, locations visited
- Status: active, completed, or game_over
- Unique `restore_key` for session identification

## Rails Conventions

This project follows Rails 8 conventions:
- RESTful routing patterns
- Convention over configuration
- Fat models, skinny controllers
- Hotwire for modern frontend interactions
- Progressive enhancement

## Working with Claude

When working on this project with Claude, please:
1. Follow Rails 8 conventions and best practices
2. Use built-in Rails features before adding gems
3. Keep the codebase simple and maintainable
4. Test changes thoroughly
5. Prefer Hotwire/Turbo over heavy JavaScript frameworks
6. Use Stimulus controllers for interactive components

## Testing

The project uses RSpec for testing with FactoryBot for test data:
```bash
# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/game_spec.rb

# Run specs with documentation format
bundle exec rspec --format documentation
```

### Testing Setup
- **RSpec**: Behavior-driven testing framework
- **FactoryBot**: Factory-based test data generation
- **Faker**: Fake data generation for tests
- **Capybara & Selenium**: System/integration testing

### Test Structure
- `spec/models/` - Model specs
- `spec/requests/` - Request specs (API/controller tests)
- `spec/system/` - System specs (full-stack feature tests)
- `spec/factories/` - FactoryBot factory definitions

### Testing Conventions

**What We Do:**
- ✅ Test public interfaces and observable behavior
- ✅ Reload database objects to verify changes (e.g., `object.reload`)
- ✅ Use spies as a last resort when reload/observation isn't practical
- ✅ Test effects rather than implementation details
- ✅ Use FactoryBot for test data

**What We Don't Do:**
- ❌ No shoulda-matchers gem
- ❌ Don't test private methods directly
- ❌ Avoid testing implementation details

## Code Quality

- **Brakeman**: Security scanning (`bin/brakeman`)
- **Rubocop**: Code style linting (`bin/rubocop`)
- **Annotaterb**: Schema annotations (`bundle exec annotaterb models`)

### After Running Migrations

After running `bin/rails db:migrate`, always run these follow-up commands:
```bash
# Update schema annotations in model files
bundle exec annotaterb models

# Replant seed data to reflect schema changes
bin/rails db:seed:replant
```

## Documentation

The `docs/` folder contains detailed design documents for different aspects of the game:

### Domain Documentation
These documents explain the game's domain models, systems, and mechanics:

- **`GAMEPLAY.md`** - Core gameplay design inspired by Drug Wars (1984)
  - Victory conditions and scoring system
  - Market dynamics and price fluctuations
  - Random events and strategic elements
  - Research on original game and modern clones

- **`events_system_design.md`** - Events system architecture
  - Tag-based event modifiers affecting resources and locations
  - Database schema for Events and GameEvents
  - Event rarity system (Common → Exceptional)
  - Three detailed event examples (Hurricane Havoc, Tech Bubble Burst, Prohibition Flashback)
  - Implementation details for tag matching and effect stacking

- **`LOCATION_TAGS.md`** - Location tagging system
  - Economic/Industry tags (tech_hub, port_city, manufacturing, etc.)
  - Demographic/Cultural tags (wealthy, tourist_destination, college_town, etc.)
  - Geographic tags (coastal, landlocked, regional classifications)
  - Tag-to-resource interaction examples
  - Example city configurations

### Task-Specific Documentation
These documents provide guidance for specific development tasks:

- **`TURNS.md`** - Turn-based action system
  - Complete breakdown of player actions (market, location, travel, encounters)
  - Turn flow and timing (what consumes turns vs. free actions)
  - Action phasing roadmap (MVP → Advanced Features)
  - UI considerations and wireframes

- **`STYLE_GUIDE.md`** - CSS/SCSS development guide
  - BEM naming conventions (Block__Element--Modifier)
  - Mid-2000s design system (colors, typography, tactile buttons)
  - dartsass auto-compilation workflow with `bin/dev`
  - Component reference (header, forms, buttons, tables, alerts)

**When to use these docs:**
- Building event-related features? → Read `events_system_design.md`
- Adding new locations? → Check `LOCATION_TAGS.md`
- Working on player actions? → Reference `TURNS.md`
- Styling components? → Follow `STYLE_GUIDE.md`
- Understanding game design? → Start with `GAMEPLAY.md`

## Deployment

This application is configured for deployment with Kamal 2.9.0.

## Resources

- [Rails 8 Guides](https://guides.rubyonrails.org/)
- [Hotwire Documentation](https://hotwired.dev/)
- [Turbo Documentation](https://turbo.hotwired.dev/)
- [Stimulus Documentation](https://stimulus.hotwired.dev/)
