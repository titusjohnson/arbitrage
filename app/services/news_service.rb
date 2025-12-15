# NewsService - Aggregates news from multiple sources into unified feed
#
# Purpose: Combine world events, market reports, player actions, and economic trends
# into a single newsfeed for the player.
#
# Usage:
#   service = NewsService.new(game, days_back: 7)
#   feed = service.unified_feed(limit: 100, news_type: nil)
#
class NewsService
  attr_reader :game, :days_back, :current_day

  # Initialize the service
  #
  # @param game [Game] The game instance
  # @param days_back [Integer] How many days of news to show
  def initialize(game, days_back: 7)
    @game = game
    @days_back = days_back
    @current_day = game.current_day
  end

  # Returns unified feed of all news types, sorted by timestamp descending
  #
  # @param limit [Integer] Maximum number of news items to return
  # @param news_type [String, nil] Filter by specific type: 'event', 'market', 'action', 'trend'
  # @return [Array<NewsItemPresenter>] Array of news items
  def unified_feed(limit: 100, news_type: nil)
    items = []

    items += event_news unless news_type && news_type != 'event'
    items += market_news unless news_type && news_type != 'market'
    items += action_news unless news_type && news_type != 'action'
    items += trend_news unless news_type && news_type != 'trend'

    items.sort_by(&:timestamp).reverse.take(limit)
  end

  private

  def cutoff_date
    @cutoff_date ||= days_back.days.ago
  end

  # Fetch event news (active and recently expired events)
  def event_news
    items = []

    # Active events
    game.game_events.active.includes(:event).each do |game_event|
      event = game_event.event
      days_elapsed = event.duration - game_event.days_remaining + 1

      items << NewsItemPresenter.new(
        headline: "#{event.name} - Day #{days_elapsed} of #{event.duration}",
        body: event.description,
        timestamp: game_event.created_at,
        news_type: 'event',
        severity: event.severity || 3,
        metadata: {
          event_type: event.event_type,
          days_remaining: game_event.days_remaining,
          affected_tags: extract_affected_tags(event)
        },
        game_day: game_event.day_triggered
      )
    end

    # Recently expired events
    game.game_events
        .expired
        .where("updated_at > ?", cutoff_date)
        .includes(:event)
        .each do |game_event|
      event = game_event.event

      items << NewsItemPresenter.new(
        headline: "#{event.name} has ended",
        body: "The #{event.event_type} event has concluded. Markets return to normal.",
        timestamp: game_event.updated_at,
        news_type: 'event',
        severity: 2,
        metadata: { event_type: event.event_type },
        game_day: calculate_game_day(game_event.updated_at)
      )
    end

    items
  end

  # Fetch market news using MarketAnalysisService
  def market_news
    items = []

    market_service = MarketAnalysisService.new(game, threshold: 0.20, days_back: days_back)
    movers = market_service.significant_movers(limit: 5)

    movers.each do |movement|
      direction_word = movement[:direction] == :increase ? "surge" : "plummet"
      change_desc = movement[:change_percent] > 0 ? "+#{movement[:change_percent]}" : movement[:change_percent]

      items << NewsItemPresenter.new(
        headline: "#{movement[:resource].name} prices #{direction_word} #{movement[:change_percent].abs}%",
        body: "Market analysts report #{movement[:resource].name} now trading at $#{movement[:current_price]}, #{direction_word}ing from $#{movement[:old_price]} #{days_back} days ago.",
        timestamp: movement[:game_resource].updated_at,
        news_type: 'market',
        severity: (movement[:change_percent].abs / 50).clamp(1, 5).to_i,
        metadata: {
          resource_id: movement[:resource].id,
          change_percent: movement[:change_percent],
          old_price: movement[:old_price],
          new_price: movement[:current_price],
          direction: movement[:direction]
        },
        game_day: current_day
      )
    end

    items
  end

  # Fetch player action news from EventLog
  # Aggregates similar purchases/sales on the same day
  def action_news
    items = []
    logs = game.event_logs
               .where("created_at > ?", cutoff_date)
               .order(created_at: :desc)

    # Group logs by date and action type for aggregation
    logs_by_date = logs.group_by { |log| log.created_at.to_date }

    logs_by_date.each do |date, day_logs|
      # Separate purchases, sales, and other actions
      purchases = day_logs.select { |log| log.message.start_with?('Purchased') }
      sales = day_logs.select { |log| log.message.start_with?('Sold') }
      others = day_logs.reject { |log| log.message.start_with?('Purchased', 'Sold') }

      # Aggregate purchases by resource
      aggregate_transactions(purchases, 'Purchased', date).each { |item| items << item }

      # Aggregate sales by resource
      aggregate_transactions(sales, 'Sold', date).each { |item| items << item }

      # Add non-transaction logs as-is
      others.each do |log|
        items << NewsItemPresenter.new(
          headline: log.message,
          body: nil,
          timestamp: log.created_at,
          news_type: 'action',
          severity: 1,
          metadata: {
            loggable_type: log.loggable_type,
            loggable_id: log.loggable_id
          },
          game_day: calculate_game_day(log.created_at)
        )
      end
    end

    items
  end

  # Aggregate similar transactions (purchases or sales) on the same day
  def aggregate_transactions(logs, action_type, date)
    items = []

    # Group by resource and price
    grouped = logs.group_by do |log|
      # Extract resource name and price from message
      # Format: "Purchased 5 Widgets for $100" or "Sold 3 Gadgets for $75"
      match = log.message.match(/#{action_type} (\d+) (.+?) for \$(\d+(?:\.\d+)?)/)
      if match
        resource_name = match[2].singularize
        price = match[3]
        "#{resource_name}|#{price}"
      else
        # If format doesn't match, use the whole message as unique key
        log.message
      end
    end

    grouped.each do |key, transaction_logs|
      if transaction_logs.length == 1
        # Single transaction, show as-is
        log = transaction_logs.first
        items << NewsItemPresenter.new(
          headline: log.message,
          body: nil,
          timestamp: log.created_at,
          news_type: 'action',
          severity: 1,
          metadata: {
            loggable_type: log.loggable_type,
            loggable_id: log.loggable_id
          },
          game_day: calculate_game_day(log.created_at)
        )
      else
        # Multiple similar transactions, aggregate them
        log = transaction_logs.first
        match = log.message.match(/#{action_type} (\d+) (.+?) for \$(\d+(?:\.\d+)?)/)

        if match
          total_quantity = transaction_logs.sum do |l|
            l.message.match(/#{action_type} (\d+)/)[1].to_i
          end

          total_cost = transaction_logs.sum do |l|
            l.message.match(/for \$(\d+(?:\.\d+)?)/)[1].to_f
          end

          resource_name = match[2].singularize

          # Check if any have event effects
          has_events = transaction_logs.any? { |l| l.message.include?('⚡') }
          event_note = has_events ? " (some with event effects)" : ""

          headline = "#{action_type} #{total_quantity} #{resource_name.pluralize(total_quantity)} " \
                     "for $#{total_cost.round(2)} in #{transaction_logs.length} transactions#{event_note}."

          items << NewsItemPresenter.new(
            headline: headline,
            body: nil,
            timestamp: log.created_at,
            news_type: 'action',
            severity: 1,
            metadata: {
              loggable_type: log.loggable_type,
              loggable_id: log.loggable_id,
              aggregated_count: transaction_logs.length
            },
            game_day: calculate_game_day(log.created_at)
          )
        else
          # Fallback: show individually if we can't parse
          transaction_logs.each do |tlog|
            items << NewsItemPresenter.new(
              headline: tlog.message,
              body: nil,
              timestamp: tlog.created_at,
              news_type: 'action',
              severity: 1,
              metadata: {
                loggable_type: tlog.loggable_type,
                loggable_id: tlog.loggable_id
              },
              game_day: calculate_game_day(tlog.created_at)
            )
          end
        end
      end
    end

    items
  end

  # Fetch economic trend news
  def trend_news
    items = []

    # Net worth summary
    items << NewsItemPresenter.new(
      headline: "Your trading empire: $#{format_currency(game.net_worth)}",
      body: "Cash: $#{format_currency(game.total_cash)}, Inventory Value: $#{format_currency(game.inventory_value)}",
      timestamp: game.updated_at,
      news_type: 'trend',
      severity: 1,
      metadata: { net_worth: game.net_worth },
      game_day: current_day
    )

    # Best deal (if exists)
    if game.best_deal_profit > 0
      items << NewsItemPresenter.new(
        headline: "Your best trade netted $#{format_currency(game.best_deal_profit)} profit",
        body: "Keep searching for deals like this!",
        timestamp: game.updated_at,
        news_type: 'trend',
        severity: 1,
        metadata: { profit: game.best_deal_profit },
        game_day: current_day
      )
    end

    items
  end

  # Extract affected tags from event's resource_effects
  def extract_affected_tags(event)
    tags = []
    if event.resource_effects.present?
      event.resource_effects['price_modifiers']&.each do |mod|
        tags.concat(mod['tags'] || [])
      end
    end
    tags.uniq
  end

  # Format currency with comma separators
  def format_currency(amount)
    amount.round(0).to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1,').reverse
  end

  # Calculate which game day a timestamp occurred on
  # Assumes the game was created on day 1
  def calculate_game_day(timestamp)
    return current_day if timestamp.nil?

    days_since_start = ((timestamp - game.started_at) / 1.day).floor
    [days_since_start + 1, 1].max.clamp(1, 30)
  end
end
