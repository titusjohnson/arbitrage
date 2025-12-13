class TravelController < ApplicationController
  def index
    @locations = Location.all.order(:name)
    @recently_visited_location_ids = current_game.recently_visited_locations.pluck(:id)
  end

  def create
    action = TravelAction.new(current_game, destination_id: params[:location_id])

    if action.run
      flash[:success] = action.log.message
      redirect_to root_path
    else
      @locations = Location.all.order(:name)
      flash[:error] = action.errors.full_messages.join(", ")
      redirect_to travel_path
    end
  end

end
