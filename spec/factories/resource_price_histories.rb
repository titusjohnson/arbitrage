# == Schema Information
#
# Table name: resource_price_histories
#
#  id               :integer          not null, primary key
#  day              :integer          not null
#  price            :decimal(10, 2)   not null
#  quantity         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  game_resource_id :integer          not null
#
# Indexes
#
#  index_price_histories_for_analysis  (game_resource_id,day,price)
#  index_price_histories_unique        (game_resource_id,day) UNIQUE
#
# Foreign Keys
#
#  game_resource_id  (game_resource_id => game_resources.id)
#
FactoryBot.define do
  factory :resource_price_history do
    association :game_resource
    day { 1 }
    price { game_resource&.current_price || 100.00 }
    quantity { game_resource&.available_quantity || 100 }
  end
end
