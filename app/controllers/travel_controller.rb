class TravelController < ApplicationController
  def index
    @locations = Location.includes(:tags).all.order(:name)
    @recently_visited_location_ids = current_game.recently_visited_locations.pluck(:id)
  end

  def create
    action = TravelAction.new(current_game, destination_id: params[:location_id])

    if action.run
      destination = Location.find(params[:location_id])
      travel_cost = extract_travel_cost(action.log.message)
      flash[:success] = cheeky_travel_message(destination.name, travel_cost)
      redirect_to root_path
    else
      @locations = Location.all.order(:name)
      flash[:error] = action.errors.full_messages.join(", ")
      redirect_to travel_path
    end
  end

  private

  def extract_travel_cost(message)
    match = message.match(/\$(\d+)/)
    match ? match[1].to_i : 0
  end

  def cheeky_travel_message(destination, cost)
    messages = travel_messages_for_cost(cost)
    messages.sample % { destination: destination, cost: cost }
  end

  def travel_messages_for_cost(cost)
    case cost
    when 0
      [
        "Hoofed it to %{destination} like a proper pauper.",
        "Mooched a ride to %{destination}. Still got it!",
        "Walked to %{destination}. Cardio is free, baby!"
      ]
    when 100
      [
        "Took a Greyhound to %{destination}. Smelled like regret.",
        "Hitched a sketchy rideshare to %{destination} for $%{cost}.",
        "Bus fare to %{destination}: $%{cost}. Dignity: priceless."
      ]
    when 200
      [
        "Road trip to %{destination}! Gas money: $%{cost}.",
        "Carpooled to %{destination}. Only $%{cost} and two awkward hours.",
        "Rented a beater to %{destination} for $%{cost}. It made noises."
      ]
    when 300
      [
        "Train to %{destination}. $%{cost} but at least there's legroom.",
        "Amtrak'd it to %{destination} for $%{cost}. Saw some cows.",
        "Rode the rails to %{destination}. $%{cost} well spent on snack car access."
      ]
    when 400
      [
        "Booked a budget flight to %{destination}. $%{cost}, no carry-on.",
        "Spirit Airlines to %{destination}: $%{cost} plus emotional damage.",
        "Flew standby to %{destination} for $%{cost}. Never again."
      ]
    when 500
      [
        "Decent flight to %{destination}. $%{cost} and they fed you!",
        "Jetted off to %{destination} for $%{cost}. Window seat!",
        "Flew to %{destination} like a respectable adult. $%{cost}."
      ]
    when 600
      [
        "First-ish class to %{destination}. $%{cost} for extra legroom.",
        "Splurged on comfort to %{destination}. $%{cost} but worth it.",
        "Premium economy to %{destination}: $%{cost}. Fancy!"
      ]
    else
      [
        "Private chartered... something to %{destination}. $%{cost}. Big spender!",
        "Travelled in style to %{destination} for $%{cost}. Bougie!",
        "Dropped $%{cost} getting to %{destination}. Money talks, baby!"
      ]
    end
  end
end
