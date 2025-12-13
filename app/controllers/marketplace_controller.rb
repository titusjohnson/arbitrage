class MarketplaceController < ApplicationController
  def index
    @location = current_game.current_location
    @location_resources = LocationResource
      .for_game_and_location(current_game, @location)
      .includes(:resource)
      .order('resources.name ASC')
  end
end
