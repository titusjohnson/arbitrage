# == Schema Information
#
# Table name: buddies
#
#  id                    :integer          not null, primary key
#  hire_cost             :integer          default(100), not null
#  hire_day              :integer          not null
#  last_sale_day         :integer
#  last_sale_profit      :decimal(10, 2)
#  name                  :string           not null
#  purchase_price        :decimal(10, 2)
#  quantity              :integer          default(0)
#  status                :string           default("idle"), not null
#  target_profit_percent :integer          default(25)
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  game_id               :integer          not null
#  location_id           :integer          not null
#  resource_id           :integer
#
# Indexes
#
#  index_buddies_on_game_id                  (game_id)
#  index_buddies_on_game_id_and_location_id  (game_id,location_id)
#  index_buddies_on_game_id_and_status       (game_id,status)
#  index_buddies_on_location_id              (location_id)
#  index_buddies_on_resource_id              (resource_id)
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#  resource_id  (resource_id => resources.id)
#
class Buddy < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :location
  belongs_to :resource, optional: true

  # Enums
  enum :status, { idle: 'idle', holding: 'holding', sold: 'sold' }

  # Validations
  validates :name, presence: true
  validates :hire_cost, presence: true, numericality: { greater_than: 0 }
  validates :hire_day, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :target_profit_percent, numericality: { greater_than: 0, less_than_or_equal_to: 200 }
  validates :quantity, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :at_location, ->(location) { where(location: location) }
  scope :for_game, ->(game) { where(game: game) }
  scope :with_pending_sales, -> { where(status: 'sold') }
  scope :actively_holding, -> { where(status: 'holding') }

  # Check if target price has been reached at buddy's location
  def target_price_reached?
    return false unless holding? && resource.present? && purchase_price.present?

    current_local_price >= target_price
  end

  # The price we need to hit for auto-sell
  def target_price
    return nil unless purchase_price.present?

    purchase_price * (1 + target_profit_percent / 100.0)
  end

  # Current price at the buddy's location
  def current_local_price
    return nil unless resource.present?

    game_resource = game.game_resources.find_by(resource: resource)
    return nil unless game_resource

    game_resource.price_at_location(location)
  end

  # Calculate current profit/loss at local prices
  def current_profit
    return 0 unless holding? && resource.present? && purchase_price.present?

    local_price = current_local_price
    return 0 unless local_price

    (local_price - purchase_price) * quantity
  end

  # Current gain as a percentage
  def current_gain_percent
    return 0 unless holding? && purchase_price.present? && purchase_price > 0

    local_price = current_local_price
    return 0 unless local_price

    ((local_price - purchase_price) / purchase_price * 100).round(1)
  end

  # Progress toward target as percentage (0-100)
  def progress_percent
    return 0 unless holding? && target_profit_percent > 0

    gain = current_gain_percent
    [(gain / target_profit_percent * 100).round, 100].min
  end

  # Total value of held resources at purchase price
  def held_value
    return 0 unless quantity > 0 && purchase_price.present?

    quantity * purchase_price
  end

  # Execute the auto-sell when target is reached
  def execute_sale!(current_day)
    return false unless target_price_reached?

    local_price = current_local_price
    profit = (local_price - purchase_price) * quantity

    update!(
      status: 'sold',
      last_sale_profit: profit,
      last_sale_day: current_day
    )

    profit
  end

  # Collect sale proceeds and reset buddy to idle
  def collect_proceeds!
    return 0 unless sold?

    total = held_value + (last_sale_profit || 0)

    game.increment!(:cash, total)

    # Reset buddy to idle state
    update!(
      status: 'idle',
      resource: nil,
      quantity: 0,
      purchase_price: nil,
      last_sale_profit: nil,
      last_sale_day: nil
    )

    total
  end

  # Name generator for new buddies
  BUDDY_NAMES = %w[
    Vinnie Marco Tony Sal Louie Frankie Joey Paulie
    Gino Rocco Enzo Nicky Carmine Dominic Angelo Vito
    Bruno Mickey Sammy Eddie Benny Dino Luca Artie
  ].freeze

  def self.generate_name
    BUDDY_NAMES.sample
  end
end
