# Called during GameTurnAction to process all buddy auto-sells
# Checks each actively-holding buddy to see if their target price has been reached
class BuddyCheckService
  attr_reader :game, :sales

  def initialize(game)
    @game = game
    @sales = []
  end

  def call
    game.buddies.actively_holding.includes(:location, :resource).find_each do |buddy|
      if buddy.target_price_reached?
        profit = buddy.execute_sale!(game.current_day)
        @sales << {
          buddy: buddy,
          resource: buddy.resource,
          quantity: buddy.quantity,
          profit: profit,
          location: buddy.location
        }
      end
    end

    @sales
  end

  def any_sales?
    @sales.any?
  end
end
