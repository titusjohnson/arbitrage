module NewsHelper
  # Returns count of unread news items (event logs) from the last 7 days
  #
  # @return [Integer] Number of unread items
  def unread_news_count
    return 0 unless current_game

    current_game.event_logs
                .unread
                .where("created_at > ?", 7.days.ago)
                .count
  end
end
