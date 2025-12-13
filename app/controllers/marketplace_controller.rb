class MarketplaceController < ApplicationController
  def index
    @game = current_game
    @location = @game.current_location
    @location_resources = LocationResource
      .for_game_and_location(@game, @location)
      .includes(resource: :tags)
      .order('resources.name ASC')

    # Get inventory for checking ownership and calculating profit/loss
    @inventory_by_resource = @game.inventory_items
      .includes(resource: :tags)
      .group_by(&:resource_id)
  end

  def buy
    @game = current_game
    @location = @game.current_location

    action = BuyAction.new(
      @game,
      location_resource_id: params[:location_resource_id],
      quantity: params[:quantity]
    )

    if action.call
      @location_resource = LocationResource.find(params[:location_resource_id])
      @inventory_by_resource = @game.inventory_items
        .includes(resource: :tags)
        .group_by(&:resource_id)

      respond_to do |format|
        format.html { redirect_to marketplace_path, notice: "Successfully purchased #{params[:quantity]} of #{action.send(:resource).name}" }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resource_#{@location_resource.id}",
              partial: "marketplace/resource_row",
              locals: {
                location_resource: @location_resource,
                game: @game,
                inventory_by_resource: @inventory_by_resource
              }
            ),
            turbo_stream.replace("game_stats",
              partial: "shared/game_stats",
              locals: { game: @game }
            ),
            turbo_stream.update("flash_messages",
              partial: "shared/flash",
              locals: { flash: { notice: "Successfully purchased #{params[:quantity]} of #{action.send(:resource).name}" } }
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to marketplace_path, alert: action.errors.full_messages.join(", ") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash",
            locals: { flash: { alert: action.errors.full_messages.join(", ") } }
          )
        end
      end
    end
  end

  def sell
    @game = current_game
    @location = @game.current_location

    action = SellAction.new(
      @game,
      location_resource_id: params[:location_resource_id],
      quantity: params[:quantity]
    )

    if action.call
      @location_resource = LocationResource.find(params[:location_resource_id])
      @inventory_by_resource = @game.inventory_items
        .includes(resource: :tags)
        .group_by(&:resource_id)

      respond_to do |format|
        format.html { redirect_to marketplace_path, notice: "Successfully sold #{params[:quantity]} of #{action.send(:resource).name}" }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resource_#{@location_resource.id}",
              partial: "marketplace/resource_row",
              locals: {
                location_resource: @location_resource,
                game: @game,
                inventory_by_resource: @inventory_by_resource
              }
            ),
            turbo_stream.replace("game_stats",
              partial: "shared/game_stats",
              locals: { game: @game }
            ),
            turbo_stream.update("flash_messages",
              partial: "shared/flash",
              locals: { flash: { notice: "Successfully sold #{params[:quantity]} of #{action.send(:resource).name}" } }
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to marketplace_path, alert: action.errors.full_messages.join(", ") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.update("flash_messages",
            partial: "shared/flash",
            locals: { flash: { alert: action.errors.full_messages.join(", ") } }
          )
        end
      end
    end
  end
end
