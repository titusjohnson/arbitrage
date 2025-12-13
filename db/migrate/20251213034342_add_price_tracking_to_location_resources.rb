class AddPriceTrackingToLocationResources < ActiveRecord::Migration[8.0]
  def change
    # price_direction: -1.0 to 1.0, indicates direction of price movement
    # Negative = prices falling, Positive = prices rising
    add_column :location_resources, :price_direction, :decimal, precision: 3, scale: 2, default: 0.0, null: false

    # price_momentum: 0.0 to 1.0, indicates strength/speed of price change
    # Higher momentum = faster price changes
    add_column :location_resources, :price_momentum, :decimal, precision: 3, scale: 2, default: 0.5, null: false

    # base_price: The "center point" around which the price oscillates
    # This is set when the resource is first created at a location
    add_column :location_resources, :base_price, :decimal, precision: 10, scale: 2
  end
end
