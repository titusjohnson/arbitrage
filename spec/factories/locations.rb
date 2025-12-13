FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Location #{n}" }
    description { "MyText" }
    sequence(:x) { |n| n % 6 }  # 0-5 as per validation
    sequence(:y) { |n| n / 6 % 5 }  # 0-4 as per validation, cycles after 6 locations
  end
end
