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
end
