class EventSpawnerService
  SPAWN_CHANCES = {
    "common" => 0.15,
    "uncommon" => 0.08,
    "rare" => 0.03,
    "ultra_rare" => 0.01,
    "exceptional" => 0.002
  }.freeze

  def initialize(game, day)
    @game = game
    @day = day
  end

  def spawn_if_eligible
    return if @game.game_events.active.exists?

    Event::RARITIES.each do |rarity|
      if should_spawn?(rarity)
        spawn_event(rarity)
        break
      end
    end
  end

  private

  def should_spawn?(rarity)
    rand < SPAWN_CHANCES[rarity]
  end

  def spawn_event(rarity)
    event = Event.where(active: true, rarity: rarity).order("RANDOM()").first
    return unless event

    @game.game_events.create!(
      event: event,
      day_triggered: @day,
      days_remaining: event.duration,
      seen: @day < 0
    )
  end
end
