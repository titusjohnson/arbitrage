# == Schema Information
#
# Table name: resources
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  description      :text
#  base_price_min   :decimal(10, 2)   not null
#  base_price_max   :decimal(10, 2)   not null
#  price_volatility :decimal(5, 2)    default(50.0), not null
#  inventory_size   :integer          default(1), not null
#  rarity           :string           default("common"), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_resources_on_name    (name) UNIQUE
#  index_resources_on_rarity  (rarity)
#
class Resource < ApplicationRecord
  # Tagging
  Gutentag::ActiveRecord.call self

  # Enums
  enum :rarity, {
    common: "common",
    uncommon: "uncommon",
    rare: "rare",
    ultra_rare: "ultra_rare",
    exceptional: "exceptional"
  }, validate: true
  # Validations
  validates :name, presence: true, uniqueness: true
  validates :base_price_min, presence: true, numericality: { greater_than: 0 }
  validates :base_price_max, presence: true, numericality: { greater_than: 0 }
  validates :price_volatility, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
  validates :inventory_size, presence: true, numericality: { only_integer: true, greater_than: 0 }

  validate :max_price_greater_than_min_price

  # Scopes
  scope :ordered_by_name, -> { order(:name) }
  scope :high_volatility, -> { where("price_volatility >= ?", 75) }
  scope :low_volatility, -> { where("price_volatility <= ?", 25) }

  # Instance methods
  def price_range
    base_price_min..base_price_max
  end

  def average_price
    (base_price_min + base_price_max) / 2
  end

  # Generate a random market price within the base range, adjusted by volatility
  # volatility affects how far from base range the price can swing
  def generate_market_price
    range_midpoint = average_price
    range_width = base_price_max - base_price_min

    # Volatility increases the potential swing beyond the base range
    volatility_multiplier = price_volatility / 100.0
    max_swing = range_width * volatility_multiplier

    # Random price can swing from -max_swing to +max_swing from midpoint
    swing = rand(-max_swing..max_swing)
    price = range_midpoint + swing

    # Ensure price never goes below 1
    [ price, 1.0 ].max.round(2)
  end

  private

  def max_price_greater_than_min_price
    if base_price_min.present? && base_price_max.present? && base_price_max <= base_price_min
      errors.add(:base_price_max, "must be greater than minimum price")
    end
  end
end
