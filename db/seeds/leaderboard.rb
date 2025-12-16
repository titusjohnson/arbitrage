# Seed completed games for leaderboard
puts "\n🏆 Seeding leaderboard games..."

# Player name components for variety
PLAYER_PREFIXES = %w[Swift Golden Shadow Lucky Mighty Clever Bold Daring Iron Steel Silver Velvet Crimson Azure Jade]
PLAYER_SUFFIXES = %w[Trader Merchant Dealer Mogul Baron Tycoon Hustler Broker Flipper Collector Hunter Hawk Fox Wolf]

def generate_player_name
  "#{PLAYER_PREFIXES.sample}#{PLAYER_SUFFIXES.sample}"
end

# Create a variety of completed games with different scores
leaderboard_games = [
  # Top performers (high scores, tycoon difficulty)
  { difficulty: :tycoon, net_worth_range: 40_000_000..50_000_000, days_ago: 3 },
  { difficulty: :tycoon, net_worth_range: 35_000_000..45_000_000, days_ago: 7 },
  { difficulty: :tycoon, net_worth_range: 30_000_000..40_000_000, days_ago: 14 },

  # Strong performers (antique_dealer)
  { difficulty: :antique_dealer, net_worth_range: 20_000_000..30_000_000, days_ago: 1 },
  { difficulty: :antique_dealer, net_worth_range: 15_000_000..25_000_000, days_ago: 5 },
  { difficulty: :antique_dealer, net_worth_range: 12_000_000..20_000_000, days_ago: 10 },
  { difficulty: :antique_dealer, net_worth_range: 10_000_000..15_000_000, days_ago: 12 },

  # Mid-tier performers
  { difficulty: :street_peddler, net_worth_range: 5_000_000..10_000_000, days_ago: 2 },
  { difficulty: :street_peddler, net_worth_range: 3_000_000..8_000_000, days_ago: 4 },
  { difficulty: :street_peddler, net_worth_range: 2_000_000..5_000_000, days_ago: 6 },
  { difficulty: :antique_dealer, net_worth_range: 5_000_000..10_000_000, days_ago: 8 },
  { difficulty: :antique_dealer, net_worth_range: 3_000_000..7_000_000, days_ago: 11 },

  # Average performers
  { difficulty: :street_peddler, net_worth_range: 500_000..2_000_000, days_ago: 1 },
  { difficulty: :street_peddler, net_worth_range: 300_000..1_500_000, days_ago: 3 },
  { difficulty: :street_peddler, net_worth_range: 200_000..1_000_000, days_ago: 5 },
  { difficulty: :street_peddler, net_worth_range: 100_000..500_000, days_ago: 7 },
  { difficulty: :street_peddler, net_worth_range: 50_000..300_000, days_ago: 9 },

  # Lower performers (still completed)
  { difficulty: :street_peddler, net_worth_range: 30_000..100_000, days_ago: 2 },
  { difficulty: :street_peddler, net_worth_range: 25_000..75_000, days_ago: 4 },
  { difficulty: :street_peddler, net_worth_range: 26_000..50_000, days_ago: 6 },

  # More variety
  { difficulty: :tycoon, net_worth_range: 25_000_000..35_000_000, days_ago: 20 },
  { difficulty: :tycoon, net_worth_range: 20_000_000..28_000_000, days_ago: 25 },
  { difficulty: :antique_dealer, net_worth_range: 8_000_000..12_000_000, days_ago: 15 },
  { difficulty: :antique_dealer, net_worth_range: 6_000_000..10_000_000, days_ago: 18 },
  { difficulty: :street_peddler, net_worth_range: 1_000_000..3_000_000, days_ago: 13 },
  { difficulty: :street_peddler, net_worth_range: 800_000..2_000_000, days_ago: 16 },
]

locations = Location.all.to_a
raise "No locations found. Run location seeds first." if locations.empty?

leaderboard_games.each_with_index do |game_config, index|
  config = Game.difficulty_config(game_config[:difficulty])

  # Generate random net worth within range
  net_worth = rand(game_config[:net_worth_range])

  # Calculate score (same formula as Game#calculate_final_score)
  score = [(net_worth / 1_000_000.0 * 2).to_i, 100].min

  # Random stats
  total_purchases = rand(50..500)
  total_sales = rand(40..total_purchases)
  locations_visited = rand(5..30)

  # Split net worth between cash and bank
  bank_pct = rand(0.3..0.8)
  bank_balance = (net_worth * bank_pct).round(2)
  cash = (net_worth * (1 - bank_pct)).round(2)

  completed_at = game_config[:days_ago].days.ago + rand(0..23).hours + rand(0..59).minutes
  started_at = completed_at - config[:day_target].days - rand(1..5).days

  game = Game.new(
    restore_key: SecureRandom.urlsafe_base64(32),
    difficulty: game_config[:difficulty],
    cash: cash,
    bank_balance: bank_balance,
    debt: 0,
    current_day: config[:day_target],
    day_target: config[:day_target],
    wealth_target: config[:wealth_target],
    health: rand(3..10),
    max_health: 10,
    inventory_capacity: 100,
    total_purchases: total_purchases,
    total_sales: total_sales,
    locations_visited: locations_visited,
    status: "completed",
    started_at: started_at,
    completed_at: completed_at,
    final_score: score,
    current_location: locations.sample
  )

  game.save!
  print "."
end

puts "\n✓ Created #{leaderboard_games.length} leaderboard games"
