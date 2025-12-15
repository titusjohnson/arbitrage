# MarketAnalysisService - Reusable market price movement analyzer
#
# Purpose: Analyze ResourcePriceHistory to identify significant price movements.
# This service is designed to be reusable across features (newsfeed, stock ticker, etc.)
#
# Usage:
#   service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
#   movers = service.significant_movers(limit: 20)
#
# Returns array of hashes:
#   [{
#     game_resource: <GameResource>,
#     resource: <Resource>,
#     old_price: 100.00,
#     current_price: 150.00,
#     change_percent: 50.0,
#     direction: :increase # or :decrease
#   }, ...]
#
class MarketAnalysisService
  attr_reader :game, :threshold, :days_back

  # Initialize the service
  #
  # @param game [Game] The game instance to analyze
  # @param threshold [Float] Minimum percent change to be considered significant (0.20 = 20%)
  # @param days_back [Integer] How many days back to compare prices
  def initialize(game, threshold: 0.20, days_back: 7)
    @game = game
    @threshold = threshold
    @days_back = days_back
  end

  # Find resources with significant price movements
  #
  # @param limit [Integer] Maximum number of results to return
  # @return [Array<Hash>] Array of price movement data hashes
  def significant_movers(limit: 20)
    current_day = game.current_day
    compare_day = [current_day - days_back, 1].max

    movers = []

    game.game_resources.includes(:resource, :price_histories).find_each do |gr|
      movement = analyze_price_movement(gr, compare_day)
      movers << movement if movement && significant?(movement[:change_percent])
    end

    # Sort by absolute change percentage (biggest movers first)
    movers.sort_by { |m| -m[:change_percent].abs }.take(limit)
  end

  private

  # Analyze price movement for a single GameResource
  #
  # @param game_resource [GameResource] The game resource to analyze
  # @param compare_day [Integer] The day to compare against
  # @return [Hash, nil] Movement data hash or nil if insufficient data
  def analyze_price_movement(game_resource, compare_day)
    old_record = game_resource.price_histories.find_by(day: compare_day)
    return nil unless old_record

    old_price = old_record.price.to_f
    return nil if old_price <= 0

    current_price = game_resource.current_price.to_f
    return nil if current_price <= 0

    change_percent = ((current_price - old_price) / old_price * 100).round(1)

    {
      game_resource: game_resource,
      resource: game_resource.resource,
      old_price: old_price.round(2),
      current_price: current_price.round(2),
      change_percent: change_percent,
      direction: change_percent >= 0 ? :increase : :decrease
    }
  end

  # Check if a price change is significant
  #
  # @param change_percent [Float] The percent change
  # @return [Boolean] True if change exceeds threshold
  def significant?(change_percent)
    change_percent.abs >= (threshold * 100)
  end
end
