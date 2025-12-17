class MarketplaceController < ApplicationController
  def index
    @game = current_game
    @location = @game.current_location

    all_game_resources = @game.game_resources
      .includes(resource: :tags)
      .order('resources.name ASC')

    # Separate local specialty resources from global resources
    local_resource_ids = Location.resources_with_affinity(@location).pluck(:id)

    @local_game_resources = all_game_resources.select { |gr| local_resource_ids.include?(gr.resource_id) }
    @global_game_resources = all_game_resources.reject { |gr| local_resource_ids.include?(gr.resource_id) }

    # Get inventory for checking ownership and calculating profit/loss
    @inventory_by_resource = @game.inventory_items
      .includes(resource: :tags)
      .group_by(&:resource_id)

    # Find inventory items that have local affinity (for "Your Holdings" section)
    inventory_resource_ids = @inventory_by_resource.keys
    @holdings_with_affinity = all_game_resources.select do |gr|
      inventory_resource_ids.include?(gr.resource_id) && local_resource_ids.include?(gr.resource_id)
    end
  end

  def buy
    @game = current_game
    @location = @game.current_location

    action = BuyAction.new(
      @game,
      game_resource_id: params[:game_resource_id],
      quantity: params[:quantity]
    )

    if action.call
      @game_resource = GameResource.find(params[:game_resource_id])
      @inventory_by_resource = @game.inventory_items
        .includes(resource: :tags)
        .group_by(&:resource_id)

      respond_to do |format|
        format.html { redirect_to marketplace_path, notice: "Successfully purchased #{params[:quantity]} of #{action.send(:resource).name}" }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resource_#{@game_resource.id}",
              partial: "marketplace/resource_row",
              locals: {
                game_resource: @game_resource,
                game: @game,
                location: @location,
                inventory_by_resource: @inventory_by_resource
              }
            ),
            turbo_stream.replace("game_stats",
              partial: "shared/game_stats",
              locals: { game: @game }
            ),
            turbo_stream.append("toast-container",
              partial: "shared/toast",
              locals: { type: "success", message: "Successfully purchased #{params[:quantity]} of #{action.send(:resource).name}" }
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to marketplace_path, alert: action.errors.full_messages.join(", ") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("toast-container",
            partial: "shared/toast",
            locals: { type: "error", message: action.errors.full_messages.join(", ") }
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
      game_resource_id: params[:game_resource_id],
      quantity: params[:quantity]
    )

    if action.call
      @game_resource = GameResource.find(params[:game_resource_id])
      @inventory_by_resource = @game.inventory_items
        .includes(resource: :tags)
        .group_by(&:resource_id)

      respond_to do |format|
        format.html { redirect_to marketplace_path, notice: "Successfully sold #{params[:quantity]} of #{action.send(:resource).name}" }
        format.turbo_stream do
          render turbo_stream: [
            turbo_stream.replace("resource_#{@game_resource.id}",
              partial: "marketplace/resource_row",
              locals: {
                game_resource: @game_resource,
                game: @game,
                location: @location,
                inventory_by_resource: @inventory_by_resource
              }
            ),
            turbo_stream.replace("game_stats",
              partial: "shared/game_stats",
              locals: { game: @game }
            ),
            turbo_stream.append("toast-container",
              partial: "shared/toast",
              locals: { type: "success", message: "Successfully sold #{params[:quantity]} of #{action.send(:resource).name}" }
            )
          ]
        end
      end
    else
      respond_to do |format|
        format.html { redirect_to marketplace_path, alert: action.errors.full_messages.join(", ") }
        format.turbo_stream do
          render turbo_stream: turbo_stream.append("toast-container",
            partial: "shared/toast",
            locals: { type: "error", message: action.errors.full_messages.join(", ") }
          )
        end
      end
    end
  end
end
