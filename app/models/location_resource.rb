# == Schema Information
#
# Table name: location_resources
#
#  id                 :integer          not null, primary key
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  location_id        :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_location_resources_on_game_and_location  (game_id,location_id)
#  index_location_resources_on_game_id            (game_id)
#  index_location_resources_on_location_id        (location_id)
#  index_location_resources_on_resource_id        (resource_id)
#  index_location_resources_unique                (game_id,location_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#  resource_id  (resource_id => resources.id)
#
class LocationResource < ApplicationRecord
  # Associations
  belongs_to :game
  belongs_to :location
  belongs_to :resource

  # Validations
  validates :current_price, presence: true, numericality: { greater_than: 0 }
  validates :last_refreshed_day, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 1 }
  validates :resource_id, uniqueness: { scope: [:game_id, :location_id], message: "already exists at this location for this game" }

  # Scopes
  scope :for_game_and_location, ->(game, location) { where(game: game, location: location) }
  scope :fresh, ->(current_day) { where("last_refreshed_day >= ?", current_day - 1) }
  scope :stale, ->(current_day) { where("last_refreshed_day < ?", current_day - 1) }

  # Class methods
  def self.seed_for_location(game, location)
    # Don't re-seed if already seeded for this game/location
    return if exists?(game: game, location: location)

    resources_to_add = select_resources_for_location(location)

    transaction do
      resources_to_add.each do |resource|
        create!(
          game: game,
          location: location,
          resource: resource,
          current_price: resource.generate_market_price,
          last_refreshed_day: game.current_day
        )
      end
    end
  end

  def self.select_resources_for_location(location)
    location_tags = location.tag_names
    selected_resources = []

    # STEP 1: Get tag-matched resources (resources whose tags match location tags)
    # This creates thematic consistency (tech_hub has technology, port_city has imports, etc.)
    if location_tags.any?
      # Find resources that share tags with the location
      tagged_resources = Resource.tagged_with(names: location_tags, match: :any)

      # Sample based on rarity distribution for tagged resources
      selected_resources += sample_by_rarity(tagged_resources, target_count: 15)
    end

    # STEP 2: Add some random resources for variety (untagged or different tags)
    # This ensures every location has diversity and prevents predictability
    all_resources = Resource.all.to_a
    remaining_resources = all_resources - selected_resources

    random_count = [8, remaining_resources.size].min
    selected_resources += remaining_resources.sample(random_count)

    # STEP 3: Ensure minimum variety (at least 10 resources per location)
    if selected_resources.size < 10
      still_remaining = all_resources - selected_resources
      needed = 10 - selected_resources.size
      selected_resources += still_remaining.sample([needed, still_remaining.size].min)
    end

    selected_resources.uniq
  end

  def self.sample_by_rarity(resources_scope, target_count:)
    # Rarity distribution percentages (sum to ~100%)
    # Common: 50%, Uncommon: 30%, Rare: 15%, Ultra Rare: 4%, Exceptional: 1%
    rarity_weights = {
      'common' => 0.50,
      'uncommon' => 0.30,
      'rare' => 0.15,
      'ultra_rare' => 0.04,
      'exceptional' => 0.01
    }

    selected = []
    resources_by_rarity = resources_scope.group_by(&:rarity)

    rarity_weights.each do |rarity, weight|
      next unless resources_by_rarity[rarity]&.any?

      # Calculate how many of this rarity to include
      count = (target_count * weight).round
      count = [count, 1].max if count > 0 # At least 1 if we're including this rarity

      available = resources_by_rarity[rarity]
      selected += available.sample([count, available.size].min)
    end

    # If we didn't hit target, randomly fill the rest
    if selected.size < target_count
      remaining = resources_scope.to_a - selected
      needed = target_count - selected.size
      selected += remaining.sample([needed, remaining.size].min)
    end

    selected
  end

  # Instance methods
  def needs_refresh?(current_day)
    last_refreshed_day < current_day
  end

  def refresh_price!(current_day)
    update!(
      current_price: resource.generate_market_price,
      last_refreshed_day: current_day
    )
  end
end
