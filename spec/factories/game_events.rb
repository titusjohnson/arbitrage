# == Schema Information
#
# Table name: game_events
#
#  id             :integer          not null, primary key
#  game_id        :integer          not null
#  event_id       :integer          not null
#  day_triggered  :integer
#  days_remaining :integer
#  seen           :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_game_events_on_event_id  (event_id)
#  index_game_events_on_game_id   (game_id)
#
# Foreign Keys
#
#  event_id  (events.id)
#  game_id   (games.id)
#
FactoryBot.define do
  factory :game_event do
    association :game
    association :event
    day_triggered { rand(1..30) }
    days_remaining { rand(1..7) }
    seen { false }

    trait :active do
      days_remaining { rand(1..7) }
    end

    trait :expired do
      days_remaining { 0 }
    end

    trait :seen do
      seen { true }
    end

    trait :unseen do
      seen { false }
    end
  end
end
