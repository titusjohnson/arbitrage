# == Schema Information
#
# Table name: location_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  base_price         :decimal(10, 2)
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  price_direction    :decimal(3, 2)    default(0.0), not null
#  price_momentum     :decimal(3, 2)    default(0.5), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  location_id        :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_location_resources_on_game_and_location  (game_id,location_id)
#  index_location_resources_on_game_id            (game_id)
#  index_location_resources_on_location_id        (location_id)
#  index_location_resources_on_resource_id        (resource_id)
#  index_location_resources_unique                (game_id,location_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#  resource_id  (resource_id => resources.id)
#
require 'rails_helper'

RSpec.describe LocationResource, type: :model do
  let(:game) { create(:game) }
  let(:location) { create(:location) }
  let(:resource) { create(:resource, price_volatility: 50) }

  describe '#update_market_dynamics!' do
    let(:location_resource) do
      create(:location_resource,
        game: game,
        location: location,
        resource: resource,
        current_price: 100.0,
        base_price: 100.0,
        available_quantity: 50,
        price_direction: 0.5,
        price_momentum: 0.5,
        last_refreshed_day: 1
      )
    end

    before do
      game.update!(current_day: 2)
    end

    it 'updates last_refreshed_day' do
      location_resource.update_market_dynamics!(2)
      expect(location_resource.last_refreshed_day).to eq(2)
    end

    it 'does not update if already refreshed for current day' do
      location_resource.update!(last_refreshed_day: 2)
      old_price = location_resource.current_price

      location_resource.update_market_dynamics!(2)

      expect(location_resource.current_price).to eq(old_price)
    end

    it 'updates current_price' do
      old_price = location_resource.current_price
      location_resource.update_market_dynamics!(2)

      expect(location_resource.current_price).not_to eq(old_price)
    end

    it 'keeps price above $1' do
      location_resource.update!(current_price: 2.0, base_price: 2.0)

      100.times do
        location_resource.update_market_dynamics!(location_resource.last_refreshed_day + 1)
      end

      expect(location_resource.current_price).to be >= 1.0
    end

    it 'keeps price within bounds of base_price' do
      location_resource.update_market_dynamics!(2)

      min_price = location_resource.base_price * 0.2
      max_price = location_resource.base_price * 1.8

      expect(location_resource.current_price).to be_between(min_price, max_price)
    end

    it 'updates price_direction' do
      location_resource.update_market_dynamics!(2)
      expect(location_resource.price_direction).to be_between(-1.0, 1.0)
    end

    it 'updates price_momentum' do
      location_resource.update_market_dynamics!(2)
      expect(location_resource.price_momentum).to be_between(0.0, 1.0)
    end

    it 'updates available_quantity' do
      old_quantity = location_resource.available_quantity
      location_resource.update_market_dynamics!(2)

      expect(location_resource.available_quantity).to be >= 0
    end

    context 'parabolic price movement' do
      it 'eventually reverses direction when price moves in one direction' do
        location_resource.update!(price_direction: 1.0, price_momentum: 1.0)

        directions = []
        30.times do |i|
          location_resource.update_market_dynamics!(i + 2)
          directions << location_resource.price_direction
        end

        # Should see some negative directions eventually (momentum decay causes reversal)
        expect(directions).to include(be < 0)
      end
    end

    context 'with high volatility resource' do
      let(:volatile_resource) { create(:resource, price_volatility: 90) }
      let(:location_resource) do
        create(:location_resource,
          game: game,
          location: location,
          resource: volatile_resource,
          current_price: 100.0,
          base_price: 100.0,
          price_direction: 0.5,
          price_momentum: 0.5,
          last_refreshed_day: 1
        )
      end

      it 'has larger price swings' do
        prices = [location_resource.current_price]

        10.times do |i|
          location_resource.update_market_dynamics!(i + 2)
          prices << location_resource.current_price
        end

        price_range = prices.max - prices.min
        expect(price_range).to be > 10 # Significant movement for volatile items
      end
    end

    context 'with low volatility resource' do
      let(:stable_resource) { create(:resource, price_volatility: 10) }
      let(:location_resource) do
        create(:location_resource,
          game: game,
          location: location,
          resource: stable_resource,
          current_price: 100.0,
          base_price: 100.0,
          price_direction: 0.5,
          price_momentum: 0.5,
          last_refreshed_day: 1
        )
      end

      it 'has smaller price swings' do
        prices = [location_resource.current_price]

        10.times do |i|
          location_resource.update_market_dynamics!(i + 2)
          prices << location_resource.current_price
        end

        price_range = prices.max - prices.min
        expect(price_range).to be < 50 # Limited movement for stable items
      end
    end
  end

  describe 'market pressure calculations' do
    let(:location_resource) do
      create(:location_resource,
        game: game,
        location: location,
        resource: resource,
        current_price: 100.0,
        base_price: 100.0,
        available_quantity: 50,
        price_direction: 0.0,
        price_momentum: 0.5,
        last_refreshed_day: 1
      )
    end

    describe '#calculate_supply_pressure' do
      it 'returns negative pressure when local supply is high' do
        # Create another location with much lower supply
        location2 = create(:location)
        create(:location_resource,
          game: game,
          location: location2,
          resource: resource,
          available_quantity: 10,
          last_refreshed_day: 1
        )

        pressure = location_resource.send(:calculate_supply_pressure)
        expect(pressure).to be < 0
      end

      it 'returns positive pressure when local supply is low' do
        # Create another location with much higher supply
        location2 = create(:location)
        create(:location_resource,
          game: game,
          location: location2,
          resource: resource,
          available_quantity: 200,
          last_refreshed_day: 1
        )

        pressure = location_resource.send(:calculate_supply_pressure)
        expect(pressure).to be > 0
      end
    end

    describe '#calculate_demand_pressure' do
      it 'returns positive pressure when player owns the resource' do
        create(:inventory_item, game: game, resource: resource, quantity: 10)

        pressure = location_resource.send(:calculate_demand_pressure)
        expect(pressure).to be > 0
      end

      it 'returns negative pressure when player does not own the resource' do
        pressure = location_resource.send(:calculate_demand_pressure)
        expect(pressure).to be < 0
      end

      it 'returns higher pressure when player is hoarding' do
        create(:inventory_item, game: game, resource: resource, quantity: 100)

        pressure = location_resource.send(:calculate_demand_pressure)
        expect(pressure).to eq(0.2)
      end
    end

    describe '#calculate_momentum_decay' do
      it 'returns negative decay for positive direction' do
        location_resource.update!(price_direction: 0.8)
        decay = location_resource.send(:calculate_momentum_decay)
        expect(decay).to be < 0
      end

      it 'returns positive decay for negative direction' do
        location_resource.update!(price_direction: -0.8)
        decay = location_resource.send(:calculate_momentum_decay)
        expect(decay).to be > 0
      end

      it 'returns zero decay for zero direction' do
        location_resource.update!(price_direction: 0.0)
        decay = location_resource.send(:calculate_momentum_decay)
        expect(decay).to eq(0.0)
      end

      it 'has stronger decay for extreme directions' do
        location_resource.update!(price_direction: 0.9)
        strong_decay = location_resource.send(:calculate_momentum_decay).abs

        location_resource.update!(price_direction: 0.3)
        weak_decay = location_resource.send(:calculate_momentum_decay).abs

        expect(strong_decay).to be > weak_decay
      end
    end
  end

  describe '.seed_for_location' do
    it 'sets base_price for new location resources' do
      LocationResource.seed_for_location(game, location)

      location_resources = LocationResource.where(game: game, location: location)
      location_resources.each do |lr|
        expect(lr.base_price).to be_present
        expect(lr.base_price).to eq(lr.current_price)
      end
    end

    it 'sets initial price_direction' do
      LocationResource.seed_for_location(game, location)

      location_resources = LocationResource.where(game: game, location: location)
      location_resources.each do |lr|
        expect(lr.price_direction).to be_between(-1.0, 1.0)
      end
    end

    it 'sets initial price_momentum to 0.5' do
      LocationResource.seed_for_location(game, location)

      location_resources = LocationResource.where(game: game, location: location)
      location_resources.each do |lr|
        expect(lr.price_momentum).to eq(0.5)
      end
    end
  end
end
