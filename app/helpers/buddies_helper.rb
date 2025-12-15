module BuddiesHelper
  # Returns count of buddies with pending sales to collect
  #
  # @return [Integer] Number of buddies with status 'sold'
  def buddies_with_sales_count
    return 0 unless current_game

    current_game.buddies_with_pending_sales.count
  end

  # Returns CSS class for buddy status
  #
  # @param buddy [Buddy] The buddy to get status class for
  # @return [String] CSS modifier class
  def buddy_status_class(buddy)
    case buddy.status
    when 'idle' then 'BuddyCard__Status--idle'
    when 'holding' then 'BuddyCard__Status--holding'
    when 'sold' then 'BuddyCard__Status--sold'
    end
  end
end
