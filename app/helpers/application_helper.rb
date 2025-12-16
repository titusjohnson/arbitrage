module ApplicationHelper
  # Format large currency values in compact form
  # e.g., 10_000_000 => "$10MM", 500_000 => "$500K", 25_000 => "$25K"
  def compact_currency(amount)
    if amount >= 1_000_000
      "$#{(amount / 1_000_000.0).round}MM"
    elsif amount >= 1_000
      "$#{(amount / 1_000.0).round}K"
    else
      number_to_currency(amount, precision: 0)
    end
  end
end
