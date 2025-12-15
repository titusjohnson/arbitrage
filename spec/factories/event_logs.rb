# == Schema Information
#
# Table name: event_logs
#
#  id            :integer          not null, primary key
#  loggable_type :string
#  message       :text             not null
#  read_at       :datetime
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  game_id       :integer          not null
#  loggable_id   :integer
#
# Indexes
#
#  index_event_logs_on_game_id                 (game_id)
#  index_event_logs_on_game_id_and_created_at  (game_id,created_at)
#  index_event_logs_on_game_id_and_read_at     (game_id,read_at)
#  index_event_logs_on_loggable                (loggable_type,loggable_id)
#
# Foreign Keys
#
#  game_id  (game_id => games.id)
#
FactoryBot.define do
  factory :event_log do
    association :game
    message { Faker::Lorem.sentence }

    # Optional polymorphic association
    trait :with_resource do
      association :loggable, factory: :resource
    end

    trait :with_location do
      association :loggable, factory: :location
    end

    trait :without_loggable do
      loggable { nil }
    end
  end
end
