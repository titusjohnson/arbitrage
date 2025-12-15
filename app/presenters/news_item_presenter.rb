# NewsItemPresenter - Formats news items for display
#
# Purpose: Provide consistent presentation layer for news items from different sources
#
class NewsItemPresenter
  attr_reader :headline, :body, :timestamp, :news_type, :severity, :metadata, :game_day

  # Initialize a news item presenter
  #
  # @param headline [String] The news headline
  # @param body [String, nil] Optional body text with more details
  # @param timestamp [DateTime] When the news occurred
  # @param news_type [String] Type: 'event', 'market', 'action', 'trend'
  # @param severity [Integer] Severity level 1-5 (affects styling)
  # @param metadata [Hash] Additional metadata about the news item
  # @param game_day [Integer, nil] Optional game day when this occurred
  def initialize(headline:, body:, timestamp:, news_type:, severity: 1, metadata: {}, game_day: nil)
    @headline = headline
    @body = body
    @timestamp = timestamp
    @news_type = news_type
    @severity = severity
    @metadata = metadata
    @game_day = game_day
  end

  # Returns CSS classes for styling the news item
  #
  # @return [String] Space-separated CSS classes
  def css_class
    "news-item news-item--#{news_type} news-item--severity-#{severity}"
  end

  # Returns icon class identifier for the news type
  #
  # @return [String] Icon class name
  def icon_class
    case news_type
    when 'event' then 'news-icon--event'
    when 'market' then 'news-icon--market'
    when 'action' then 'news-icon--action'
    when 'trend' then 'news-icon--trend'
    else 'news-icon--default'
    end
  end

  # Returns icon emoji for the news type
  #
  # @return [String] Emoji character
  def icon_emoji
    case news_type
    when 'event' then '⚡'
    when 'market' then '📈'
    when 'action' then '💼'
    when 'trend' then '📊'
    else '📰'
    end
  end

  # Returns human-readable formatted timestamp
  #
  # @return [String] Formatted date/time string
  def formatted_time
    timestamp.strftime("%B %d at %I:%M %p")
  end

  # Returns formatted date for grouping
  #
  # @return [String] Formatted date string
  def formatted_date
    timestamp.strftime("%A, %B %d, %Y")
  end
end
