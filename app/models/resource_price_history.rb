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
class ResourcePriceHistory < ApplicationRecord
  belongs_to :game_resource

  validates :day, presence: true, uniqueness: { scope: :game_resource_id }
  validates :price, presence: true, numericality: { greater_than: 0 }
  validates :quantity, presence: true, numericality: { greater_than_or_equal_to: 0 }

  scope :for_day, ->(day) { where(day: day) }
  scope :between_days, ->(start_day, end_day) { where(day: start_day..end_day) }
  scope :ordered, -> { order(:day) }
end
