class NewsController < ApplicationController
  def index
    # Parse parameters
    days_back = (params[:days_back] || 7).to_i.clamp(1, 30)
    news_type = params[:type] # nil, 'event', 'market', 'action', 'trend'

    # Generate newsfeed
    @news_service = NewsService.new(current_game, days_back: days_back)
    @news_feed = @news_service.unified_feed(limit: 100, news_type: news_type)

    # Store filter state for view
    @days_back = days_back
    @current_filter = news_type

    # Sidebar data
    @inventory_opportunities = build_inventory_opportunities
    @top_movers = build_top_movers

    # Mark unread event_logs as read
    mark_news_as_read
  end

  private

  def mark_news_as_read
    current_game.event_logs
                .unread
                .where("created_at > ?", 7.days.ago)
                .update_all(read_at: Time.current)
  end

  def build_inventory_opportunities
    location = current_game.current_location
    inventory_items = current_game.inventory_items.includes(:resource).group_by(&:resource_id)

    opportunities = []

    inventory_items.each do |resource_id, items|
      game_resource = current_game.game_resources.includes(:resource).find_by(resource_id: resource_id)
      next unless game_resource

      total_quantity = items.sum(&:quantity)
      avg_purchase_price = items.sum(&:total_value) / total_quantity
      current_price = game_resource.price_at_location(location)
      price_diff = current_price - avg_purchase_price
      percent_diff = ((price_diff / avg_purchase_price) * 100).round(1)

      opportunities << {
        resource: game_resource.resource,
        quantity: total_quantity,
        avg_purchase_price: avg_purchase_price.round(2),
        current_price: current_price.round(2),
        price_diff: price_diff.round(2),
        percent_diff: percent_diff
      }
    end

    opportunities.sort_by { |o| -o[:percent_diff] }
  end

  def build_top_movers
    current_day = current_game.current_day
    location = current_game.current_location

    movers = []

    current_game.game_resources.includes(:resource, :price_histories).each do |gr|
      # Get the two most recent price history records to compare
      recent_records = gr.price_histories.order(day: :desc).limit(2).to_a

      next unless recent_records.length == 2

      new_record = recent_records[0]
      old_record = recent_records[1]

      old_price = old_record.price.to_f
      new_price = new_record.price.to_f
      local_price = gr.price_at_location(location).to_f

      next if old_price <= 0

      change_percent = ((new_price - old_price) / old_price * 100).round(1)

      movers << {
        resource: gr.resource,
        old_price: old_price.round(2),
        new_price: new_price.round(2),
        local_price: local_price.round(2),
        change_percent: change_percent,
        direction: change_percent >= 0 ? :up : :down
      }
    end

    movers.sort_by { |m| -m[:change_percent].abs }.first(6)
  end
end
