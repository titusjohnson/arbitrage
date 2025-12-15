# Defines which resource tags have affinity with which location tags
# Resources with matching tags are considered "local specialties" for that location
module LocationAffinity
  extend ActiveSupport::Concern

  # Maps location tags to the resource tags they have affinity with
  # Based on docs/LOCATION_TAGS.md
  LOCATION_TO_RESOURCE_TAGS = {
    # Economic/Industry Tags
    'tech_hub' => %w[technology],
    'financial_center' => %w[precious_metal investment],
    'manufacturing' => %w[technology],
    'port_city' => %w[asian_origin european_origin],
    'agricultural' => %w[food perishable],
    'entertainment' => %w[collectible],
    'luxury_market' => %w[luxury_fashion timepiece artisan],
    'art_culture' => %w[collectible antique artisan],
    'gambling' => %w[alcohol luxury_fashion],

    # Demographic/Cultural Tags
    'wealthy' => %w[investment luxury_fashion timepiece gemstone],
    'tourist_destination' => %w[collectible artisan food],
    'college_town' => %w[technology consumable],
    'hipster' => %w[artisan food collectible],

    # Geographic Tags
    'coastal' => %w[food perishable],
    'northeastern' => %w[antique european_origin],
    'southern' => %w[food alcohol],
    'western' => %w[artisan]
  }.freeze

  class_methods do
    # Get all resource tags that have affinity with a location's tags
    def resource_tags_for_location(location)
      location_tag_names = location.tag_names
      resource_tags = []

      location_tag_names.each do |loc_tag|
        if LOCATION_TO_RESOURCE_TAGS[loc_tag]
          resource_tags.concat(LOCATION_TO_RESOURCE_TAGS[loc_tag])
        end
      end

      resource_tags.uniq
    end

    # Check if a resource has affinity with a location
    def resource_has_affinity?(resource, location)
      affinity_tags = resource_tags_for_location(location)
      return false if affinity_tags.empty?

      resource_tag_names = resource.tag_names
      (affinity_tags & resource_tag_names).any?
    end

    # Get all resources that have affinity with a location
    def resources_with_affinity(location)
      affinity_tags = resource_tags_for_location(location)
      return Resource.none if affinity_tags.empty?

      Resource.tagged_with(names: affinity_tags, match: :any)
    end
  end
end
