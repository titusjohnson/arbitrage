# == Schema Information
#
# Table name: games
#
#  id                  :integer          not null, primary key
#  bank_balance        :decimal(10, 2)   default(0.0), not null
#  best_deal_profit    :decimal(10, 2)   default(0.0), not null
#  cash                :decimal(10, 2)   default(2000.0), not null
#  completed_at        :datetime
#  current_day         :integer          default(1), not null
#  debt                :decimal(10, 2)   default(0.0), not null
#  final_score         :integer
#  health              :integer          default(10), not null
#  inventory_capacity  :integer          default(100), not null
#  locations_visited   :integer          default(1), not null
#  max_health          :integer          default(10), not null
#  restore_key         :string           not null
#  started_at          :datetime         not null
#  status              :string           default("active"), not null
#  total_purchases     :integer          default(0), not null
#  total_sales         :integer          default(0), not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  current_location_id :integer
#
# Indexes
#
#  index_games_on_player_id_and_status  (status)
#  index_games_on_restore_key           (restore_key) UNIQUE
#  index_games_on_started_at            (started_at)
#  index_games_on_status                (status)
#
FactoryBot.define do
  factory :game do
    # Game progress - defaults match migration
    current_day { 1 }
    association :current_location, factory: :location

    # Financial state - defaults match migration
    cash { 2000.00 }
    bank_balance { 0.00 }
    debt { 0.00 }

    # Game state - defaults match migration
    status { "active" }
    final_score { nil }
    health { 10 }
    max_health { 10 }
    inventory_capacity { 100 }

    # Timestamps
    started_at { Time.current }
    completed_at { nil }

    # Statistics - defaults match migration
    total_purchases { 0 }
    total_sales { 0 }
    locations_visited { 1 }
    best_deal_profit { 0.00 }

    # Traits for different game states
    trait :in_progress do
      current_day { 15 }
      cash { 5000.00 }
      bank_balance { 10000.00 }
      total_purchases { 20 }
      total_sales { 18 }
      locations_visited { 5 }
    end

    trait :near_end do
      current_day { 28 }
      cash { 25000.00 }
      bank_balance { 50000.00 }
    end

    trait :completed do
      status { "completed" }
      current_day { 30 }
      completed_at { Time.current }
      final_score { 50 }
    end

    trait :game_over do
      status { "game_over" }
      health { 0 }
      completed_at { Time.current }
      final_score { 20 }
    end

    trait :wealthy do
      cash { 100000.00 }
      bank_balance { 500000.00 }
    end

    trait :in_debt do
      debt { 5000.00 }
    end
  end
end
