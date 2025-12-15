class BuddiesController < ApplicationController
  include GameSession
  include ActionView::RecordIdentifier

  def index
    @buddies = current_game.buddies.includes(:location, :resource)
    @buddies_here = current_game.buddies_at_location(current_game.current_location).includes(:resource)
    @buddies_elsewhere = @buddies.where.not(location: current_game.current_location)
    @current_location = current_game.current_location
  end

  def show
    @buddy = current_game.buddies.includes(:location, :resource).find(params[:id])
    @at_buddy_location = @buddy.location_id == current_game.current_location_id
    @inventory_items = current_game.inventory_items.includes(:resource).order("resources.name")
  end

  def create
    action = HireBuddyAction.new(current_game, location_id: current_game.current_location_id)

    if action.call
      @buddy = action.buddy
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.prepend("buddies-here", partial: "buddies/buddy_card", locals: { buddy: @buddy, at_buddy_location: true }),
            turbo_stream.replace("game-stats", partial: "shared/game_stats", locals: { game: current_game }),
            turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: "Hired #{@buddy.name} for $100!", type: "success" })
          ]
        }
        format.html { redirect_to buddies_path, notice: "Hired #{@buddy.name}!" }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: action.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to buddies_path, alert: action.errors.full_messages.join(", ") }
      end
    end
  end

  def assign
    @buddy = current_game.buddies.find(params[:id])
    action = AssignBuddyResourceAction.new(current_game, assign_params.merge(buddy_id: @buddy.id))

    if action.call
      @buddy.reload
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace(dom_id(@buddy), partial: "buddies/buddy_card", locals: { buddy: @buddy, at_buddy_location: true }),
            turbo_stream.replace("game-stats", partial: "shared/game_stats", locals: { game: current_game }),
            turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: "Gave #{@buddy.resource.name} to #{@buddy.name}!", type: "success" })
          ]
        }
        format.html { redirect_to buddies_path, notice: "Resource assigned to #{@buddy.name}!" }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: action.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to buddy_path(@buddy), alert: action.errors.full_messages.join(", ") }
      end
    end
  end

  def collect
    @buddy = current_game.buddies.find(params[:id])
    action = CollectBuddySaleAction.new(current_game, buddy_id: @buddy.id)

    if action.call
      total = action.total_collected
      @buddy.reload
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: [
            turbo_stream.replace(dom_id(@buddy), partial: "buddies/buddy_card", locals: { buddy: @buddy, at_buddy_location: true }),
            turbo_stream.replace("game-stats", partial: "shared/game_stats", locals: { game: current_game }),
            turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: "Collected $#{total.round(2)} from #{@buddy.name}!", type: "success" })
          ]
        }
        format.html { redirect_to buddies_path, notice: "Collected $#{total.round(2)}!" }
      end
    else
      respond_to do |format|
        format.turbo_stream {
          render turbo_stream: turbo_stream.append("toast-container", partial: "shared/toast", locals: { message: action.errors.full_messages.join(", "), type: "error" })
        }
        format.html { redirect_to buddies_path, alert: action.errors.full_messages.join(", ") }
      end
    end
  end

  private

  def assign_params
    params.require(:buddy).permit(:resource_id, :quantity, :target_profit_percent)
  end
end
