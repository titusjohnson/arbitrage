FactoryBot.define do
  factory :location_visit do
    association :game
    association :location
    visited_on { 1 }
  end
end
