# == Schema Information
#
# Table name: events
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  description      :text
#  day_start        :integer
#  duration         :integer
#  active           :boolean          default(FALSE)
#  resource_effects :json
#  location_effects :json
#  event_type       :string
#  severity         :integer
#  rarity           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
FactoryBot.define do
  factory :event do
    sequence(:name) { |n| "Event #{n}" }
    description { "A significant market event affecting various resources and locations." }
    day_start { rand(1..30) }
    duration { rand(1..7) }
    active { false }
    event_type { Event::EVENT_TYPES.sample }
    severity { rand(1..5) }
    rarity { "common" }
    resource_effects do
      {
        "price_modifiers" => [
          {
            "tags" => ["food"],
            "match" => "any",
            "multiplier" => 1.5,
            "description" => "Food prices increase"
          }
        ]
      }
    end
    location_effects { {} }

    trait :common do
      rarity { "common" }
      severity { rand(1..2) }
      duration { rand(1..3) }
    end

    trait :uncommon do
      rarity { "uncommon" }
      severity { rand(2..3) }
      duration { rand(2..4) }
    end

    trait :rare do
      rarity { "rare" }
      severity { rand(3..4) }
      duration { rand(3..5) }
    end

    trait :ultra_rare do
      rarity { "ultra_rare" }
      severity { rand(4..5) }
      duration { rand(4..6) }
    end

    trait :exceptional do
      rarity { "exceptional" }
      severity { 5 }
      duration { rand(5..7) }
    end

    trait :active do
      active { true }
    end

    trait :market do
      event_type { "market" }
    end

    trait :weather do
      event_type { "weather" }
    end

    trait :political do
      event_type { "political" }
    end

    trait :cultural do
      event_type { "cultural" }
    end

    trait :with_resource_effects do
      resource_effects do
        {
          "price_modifiers" => [
            {
              "tags" => ["food", "perishable"],
              "match" => "all",
              "multiplier" => 2.5,
              "description" => "Perishable food prices spike"
            }
          ],
          "availability_modifiers" => [
            {
              "tags" => ["bulky"],
              "match" => "any",
              "multiplier" => 0.3,
              "description" => "Bulky items less available"
            }
          ]
        }
      end
    end

    trait :with_location_effects do
      location_effects do
        {
          "access_restrictions" => [
            {
              "scoped_tags" => {
                "location" => ["coastal"]
              },
              "blocked" => true,
              "description" => "Coastal cities inaccessible"
            }
          ]
        }
      end
    end
  end
end
