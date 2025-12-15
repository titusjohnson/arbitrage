class InventoryController < ApplicationController
  def index
    @game = current_game
    @inventory_items = @game.inventory_items.includes(:resource).order('resources.name ASC')
    @buddy_holdings = @game.buddies.actively_holding.includes(:resource, :location)
  end
end
