require 'rails_helper'

RSpec.describe BuddyCheckService do
  let(:location) { create(:location) }
  let(:game) { create(:game, current_location: location, current_day: 5) }
  let(:resource) { create(:resource, name: "Gold Bar") }

  describe '#call' do
    context 'when no buddies are holding resources' do
      it 'returns empty sales array' do
        create(:buddy, game: game, location: location, status: 'idle')

        service = described_class.new(game)
        sales = service.call

        expect(sales).to be_empty
      end
    end

    context 'when buddy target price is not reached' do
      it 'does not execute sale' do
        game_resource = create(:game_resource, game: game, resource: resource, current_price: 100.0)
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          target_profit_percent: 25
        )

        service = described_class.new(game)
        sales = service.call

        expect(sales).to be_empty
        expect(buddy.reload.status).to eq('holding')
      end
    end

    context 'when buddy target price is reached' do
      it 'executes the sale' do
        game_resource = create(:game_resource, game: game, resource: resource, current_price: 130.0)
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        service = described_class.new(game)
        sales = service.call

        expect(sales.length).to eq(1)
        expect(buddy.reload.status).to eq('sold')
      end

      it 'returns sale details' do
        game_resource = create(:game_resource, game: game, resource: resource, current_price: 130.0)
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        service = described_class.new(game)
        sales = service.call

        sale = sales.first
        expect(sale[:buddy]).to eq(buddy)
        expect(sale[:resource]).to eq(resource)
        expect(sale[:quantity]).to eq(5)
        expect(sale[:profit]).to eq(150.0) # (130 - 100) * 5
        expect(sale[:location]).to eq(location)
      end

      it 'sets last_sale_profit on buddy' do
        game_resource = create(:game_resource, game: game, resource: resource, current_price: 130.0)
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        described_class.new(game).call

        expect(buddy.reload.last_sale_profit).to eq(150.0)
      end

      it 'sets last_sale_day on buddy' do
        game_resource = create(:game_resource, game: game, resource: resource, current_price: 130.0)
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        described_class.new(game).call

        expect(buddy.reload.last_sale_day).to eq(5)
      end
    end

    context 'with multiple buddies' do
      it 'processes all buddies that meet target' do
        game_resource = create(:game_resource, game: game, resource: resource, current_price: 130.0)

        buddy1 = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        buddy2 = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 3,
          target_profit_percent: 20
        )

        # This one won't sell - target not reached
        buddy3 = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 2,
          target_profit_percent: 50
        )

        service = described_class.new(game)
        sales = service.call

        expect(sales.length).to eq(2)
        expect(buddy1.reload.status).to eq('sold')
        expect(buddy2.reload.status).to eq('sold')
        expect(buddy3.reload.status).to eq('holding')
      end
    end
  end

  describe '#any_sales?' do
    it 'returns true when sales occurred' do
      game_resource = create(:game_resource, game: game, resource: resource, current_price: 130.0)
      create(:buddy, :holding,
        game: game,
        location: location,
        resource: resource,
        purchase_price: 100.0,
        target_profit_percent: 25
      )

      service = described_class.new(game)
      service.call

      expect(service.any_sales?).to be true
    end

    it 'returns false when no sales occurred' do
      create(:buddy, game: game, location: location, status: 'idle')

      service = described_class.new(game)
      service.call

      expect(service.any_sales?).to be false
    end
  end
end
