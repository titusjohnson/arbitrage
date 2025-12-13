class MarketplaceController < ApplicationController
  def index
    @location = current_game.current_location
    @location_resources = LocationResource
      .for_game_and_location(current_game, @location)
      .includes(:resource)
      .order('resources.name ASC')

    # Get inventory for checking ownership and calculating profit/loss
    @inventory_by_resource = current_game.inventory_items
      .includes(:resource)
      .group_by(&:resource_id)
  end

  def buy
    action = BuyAction.new(
      current_game,
      location_resource_id: params[:location_resource_id],
      quantity: params[:quantity]
    )

    if action.call
      redirect_to marketplace_path, notice: "Successfully purchased #{params[:quantity]} of #{action.send(:resource).name}"
    else
      redirect_to marketplace_path, alert: action.errors.full_messages.join(", ")
    end
  end

  def sell
    action = SellAction.new(
      current_game,
      location_resource_id: params[:location_resource_id],
      quantity: params[:quantity]
    )

    if action.call
      redirect_to marketplace_path, notice: "Successfully sold #{params[:quantity]} of #{action.send(:resource).name}"
    else
      redirect_to marketplace_path, alert: action.errors.full_messages.join(", ")
    end
  end
end
