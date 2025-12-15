# Service to calculate cumulative event effects on a GameResource
# Handles multiple concurrent events and their tag-based modifiers
#
# Usage:
#   # Game-wide effects only (no location bonuses)
#   effects = EventEffectsService.new(game, game_resource).call
#
#   # With location bonuses
#   effects = EventEffectsService.new(game, game_resource, location: current_location).call
#
#   modified_price = base_price * effects[:price_multiplier]
#   modified_availability = base_availability * effects[:availability_multiplier]
class EventEffectsService
  attr_reader :game, :game_resource, :resource, :location

  def initialize(game, game_resource, location: nil)
    @game = game
    @game_resource = game_resource
    @resource = game_resource.resource
    @location = location
  end

  def call
    {
      price_multiplier: calculate_price_multiplier,
      availability_multiplier: calculate_availability_multiplier
    }
  end

  private

  def active_game_events
    @active_game_events ||= game.game_events.active.includes(:event)
  end

  def calculate_price_multiplier
    multiplier = 1.0

    active_game_events.each do |game_event|
      event = game_event.event

      # Apply resource-level price modifiers (game-wide)
      if event.resource_effects.present? && event.resource_effects['price_modifiers']
        event.resource_effects['price_modifiers'].each do |modifier|
          if tags_match?(modifier, resource.tags)
            multiplier *= modifier['multiplier']
          end
        end
      end

      # Apply location-scoped price modifiers (only if location provided)
      if location.present? && event.location_effects.present? && event.location_effects['price_modifiers']
        event.location_effects['price_modifiers'].each do |modifier|
          if scoped_tags_match?(modifier, location.tags, resource.tags)
            multiplier *= modifier['multiplier']
          end
        end
      end
    end

    multiplier
  end

  def calculate_availability_multiplier
    multiplier = 1.0

    active_game_events.each do |game_event|
      event = game_event.event

      # Apply resource-level availability modifiers (game-wide)
      if event.resource_effects.present? && event.resource_effects['availability_modifiers']
        event.resource_effects['availability_modifiers'].each do |modifier|
          if tags_match?(modifier, resource.tags)
            multiplier *= modifier['multiplier']
          end
        end
      end

      # Apply location-scoped quantity modifiers (only if location provided)
      if location.present? && event.location_effects.present? && event.location_effects['quantity_modifiers']
        event.location_effects['quantity_modifiers'].each do |modifier|
          if scoped_tags_match?(modifier, location.tags, resource.tags)
            multiplier *= modifier['multiplier']
          end
        end
      end
    end

    multiplier
  end

  # Check if resource tags match the modifier's tag requirements
  def tags_match?(modifier, resource_tags)
    modifier_tags = modifier['tags'] || []
    return false if modifier_tags.empty?

    resource_tag_names = resource_tags.map(&:name)
    match_type = modifier['match'] || 'any'

    case match_type
    when 'any'
      # At least one tag must match
      (modifier_tags & resource_tag_names).any?
    when 'all'
      # All modifier tags must be present
      (modifier_tags - resource_tag_names).empty?
    else
      false
    end
  end

  # Check if scoped tags match (for location-based modifiers)
  def scoped_tags_match?(modifier, location_tags, resource_tags)
    scoped_tags = modifier['scoped_tags'] || {}
    return false if scoped_tags.empty?

    location_tag_names = location_tags.map(&:name)
    resource_tag_names = resource_tags.map(&:name)

    match_type = modifier['match'] || 'any'

    location_match = if scoped_tags['location'].present?
      location_required = scoped_tags['location']
      case match_type
      when 'any'
        (location_required & location_tag_names).any?
      when 'all'
        (location_required - location_tag_names).empty?
      end
    else
      true # No location requirement
    end

    resource_match = if scoped_tags['resource'].present?
      resource_required = scoped_tags['resource']
      case match_type
      when 'any'
        (resource_required & resource_tag_names).any?
      when 'all'
        (resource_required - resource_tag_names).empty?
      end
    else
      true # No resource requirement
    end

    location_match && resource_match
  end
end
