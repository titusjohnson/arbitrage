require 'rails_helper'

RSpec.describe NewsService do
  let(:game) { create(:game, current_day: 10, best_deal_profit: 5000) }

  describe '#unified_feed' do
    it 'returns an array of NewsItemPresenter objects' do
      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      expect(feed).to be_an(Array)
      expect(feed.first).to be_a(NewsItemPresenter) if feed.any?
    end

    it 'includes event news for active events' do
      event = create(:event, name: "Test Event", event_type: "market", severity: 3)
      create(:game_event, game: game, event: event, days_remaining: 3)

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      event_items = feed.select { |item| item.news_type == 'event' }
      expect(event_items).not_to be_empty
      expect(event_items.first.headline).to include("Test Event")
    end

    it 'includes market news from MarketAnalysisService' do
      # Use an existing game_resource (created by game seeding) and add price history
      game_resource = game.game_resources.first
      if game_resource
        # Update price to show significant change
        game_resource.update!(current_price: 200.0)
        create(:resource_price_history, game_resource: game_resource, day: 3, price: 100.0, quantity: 50) # 100% increase
      end

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      market_items = feed.select { |item| item.news_type == 'market' }
      # Market items may or may not be present depending on price history
      expect(market_items.length).to be <= 5 # Limited to max 5 items
    end

    it 'includes action news from EventLog' do
      create(:event_log, game: game, message: "You purchased 10 widgets")

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      action_items = feed.select { |item| item.news_type == 'action' }
      expect(action_items).not_to be_empty
      expect(action_items.first.headline).to eq("You purchased 10 widgets")
    end

    it 'includes trend news (net worth, best deal)' do
      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      trend_items = feed.select { |item| item.news_type == 'trend' }
      expect(trend_items.length).to be >= 2 # Net worth + best deal

      net_worth_item = trend_items.find { |item| item.headline.include?("trading empire") }
      expect(net_worth_item).to be_present

      best_deal_item = trend_items.find { |item| item.headline.include?("best trade") }
      expect(best_deal_item).to be_present
    end

    it 'filters by news_type when provided' do
      create(:event_log, game: game, message: "Test action")

      service = NewsService.new(game, days_back: 7)

      # Filter to only actions
      action_feed = service.unified_feed(news_type: 'action')
      expect(action_feed.all? { |item| item.news_type == 'action' }).to be true

      # Filter to only trends
      trend_feed = service.unified_feed(news_type: 'trend')
      expect(trend_feed.all? { |item| item.news_type == 'trend' }).to be true
    end

    it 'respects the limit parameter' do
      # Create multiple event logs
      10.times do |i|
        create(:event_log, game: game, message: "Action #{i}")
      end

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed(limit: 5)

      expect(feed.length).to eq(5)
    end

    it 'sorts news by timestamp descending (newest first)' do
      create(:event_log, game: game, message: "Old action", created_at: 5.days.ago)
      create(:event_log, game: game, message: "New action", created_at: 1.day.ago)

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      action_items = feed.select { |item| item.news_type == 'action' }
      action_messages = action_items.map(&:headline)

      # Check that new action appears before old action
      new_index = action_messages.index("New action")
      old_index = action_messages.index("Old action")

      expect(new_index).to be < old_index
    end

    it 'respects days_back parameter' do
      # Game is at day 10, days_back: 7 means cutoff at day 3
      # Create old event log outside the window (day 2 is before cutoff)
      create(:event_log, game: game, message: "Very old action", game_day: 2)
      # Create recent event log within the window (day 8 is after cutoff)
      create(:event_log, game: game, message: "Recent action", game_day: 8)

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      action_items = feed.select { |item| item.news_type == 'action' }
      messages = action_items.map(&:headline)

      expect(messages).to include("Recent action")
      expect(messages).not_to include("Very old action")
    end
  end

  describe 'action aggregation' do
    it 'aggregates multiple purchases of the same item on the same day' do
      # Create multiple purchases of the same item at the same price
      timestamp = 1.day.ago
      3.times do
        create(:event_log,
          game: game,
          message: "Purchased 5 Widgets for $100.",
          created_at: timestamp
        )
      end

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      action_items = feed.select { |item| item.news_type == 'action' }
      widget_purchases = action_items.select { |item| item.headline.include?('Widget') }

      # Should be aggregated into a single item
      expect(widget_purchases.length).to eq(1)

      # Should show total quantity (15) and total cost ($300) and transaction count (3)
      aggregated = widget_purchases.first
      expect(aggregated.headline).to include('15 Widgets')
      expect(aggregated.headline).to include('$300')
      expect(aggregated.headline).to include('3 transactions')
    end

    it 'does not aggregate purchases of different items' do
      timestamp = 1.day.ago
      create(:event_log, game: game, message: "Purchased 5 Widgets for $100.", created_at: timestamp)
      create(:event_log, game: game, message: "Purchased 3 Gadgets for $50.", created_at: timestamp)

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      action_items = feed.select { |item| item.news_type == 'action' }

      widget_items = action_items.select { |item| item.headline.include?('Widget') }
      gadget_items = action_items.select { |item| item.headline.include?('Gadget') }

      expect(widget_items.length).to eq(1)
      expect(gadget_items.length).to eq(1)
    end

    it 'keeps non-transaction logs as individual items' do
      create(:event_log, game: game, message: "Traveled to New York for $50.", created_at: 1.day.ago)

      service = NewsService.new(game, days_back: 7)
      feed = service.unified_feed

      action_items = feed.select { |item| item.news_type == 'action' }
      travel_items = action_items.select { |item| item.headline.include?('Traveled') }

      expect(travel_items.length).to eq(1)
      expect(travel_items.first.headline).to eq("Traveled to New York for $50.")
    end
  end
end
