# == Schema Information
#
# Table name: locations
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  population  :integer          default(0), not null
#  x           :integer          not null
#  y           :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_locations_on_x_and_y  (x,y) UNIQUE
#
FactoryBot.define do
  factory :location do
    sequence(:name) { |n| "Location #{n}" }
    description { "MyText" }
    sequence(:x) { |n| n % 6 }  # 0-5 as per validation
    sequence(:y) { |n| n / 6 % 5 }  # 0-4 as per validation, cycles after 6 locations
  end
end
