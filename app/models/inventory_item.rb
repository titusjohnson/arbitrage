# == Schema Information
#
# Table name: inventory_items
#
#  id                   :integer          not null, primary key
#  game_id              :integer          not null
#  resource_id          :integer          not null
#  quantity             :integer          default(1), not null
#  purchase_price       :decimal(10, 2)   not null
#  purchase_day         :integer          not null
#  purchase_location_id :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_inventory_items_on_game_id                  (game_id)
#  index_inventory_items_on_game_id_and_resource_id  (game_id,resource_id)
#  index_inventory_items_on_resource_id              (resource_id)
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  resource_id  (resource_id => resources.id)
#
class InventoryItem < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :resource
  belongs_to :purchase_location, class_name: 'Location', optional: true

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :purchase_price, presence: true, numericality: { greater_than: 0 }
  validates :purchase_day, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 30 }

  # Scopes
  scope :fifo, -> { order(created_at: :asc) }
  scope :by_resource, ->(resource) { where(resource: resource) }

  # Instance methods
  def total_value
    quantity * purchase_price
  end
end
