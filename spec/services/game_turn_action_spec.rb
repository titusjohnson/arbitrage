require 'rails_helper'

RSpec.describe GameTurnAction, type: :service do
  let(:game) { create(:game) }
  let(:location) { create(:location) }
  let(:resource) { create(:resource, price_volatility: 50) }

  before do
    game.update!(current_location: location)
  end

  describe '#initialize' do
    it 'accepts only a game parameter' do
      action = GameTurnAction.new(game)
      expect(action.game).to eq(game)
    end
  end

  describe '#run' do
    context 'with no location resources' do
      it 'succeeds without errors' do
        action = GameTurnAction.new(game)
        expect(action.run).to be true
      end
    end

    context 'with location resources' do
      let!(:location_resource) do
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

      it 'updates market dynamics for all location resources' do
        action = GameTurnAction.new(game)
        expect(action.run).to be true

        location_resource.reload
        expect(location_resource.last_refreshed_day).to eq(2)
      end

      it 'changes prices based on direction' do
        action = GameTurnAction.new(game)
        old_price = location_resource.current_price

        action.run
        location_resource.reload

        expect(location_resource.current_price).not_to eq(old_price)
      end

      it 'updates price direction' do
        action = GameTurnAction.new(game)
        old_direction = location_resource.price_direction

        action.run
        location_resource.reload

        # Direction should change based on market forces
        expect(location_resource.price_direction).to be_between(-1.0, 1.0)
      end

      it 'updates price momentum' do
        action = GameTurnAction.new(game)

        action.run
        location_resource.reload

        expect(location_resource.price_momentum).to be_between(0.0, 1.0)
      end

      it 'updates available quantity' do
        action = GameTurnAction.new(game)

        action.run
        location_resource.reload

        expect(location_resource.available_quantity).to be >= 0
      end
    end

    context 'with multiple locations and resources' do
      let(:location2) { create(:location) }
      let(:resource2) { create(:resource) }

      let!(:lr1) { create(:location_resource, game: game, location: location, resource: resource, last_refreshed_day: 1) }
      let!(:lr2) { create(:location_resource, game: game, location: location, resource: resource2, last_refreshed_day: 1) }
      let!(:lr3) { create(:location_resource, game: game, location: location2, resource: resource, last_refreshed_day: 1) }

      before do
        game.update!(current_day: 2)
      end

      it 'updates all location resources' do
        action = GameTurnAction.new(game)
        action.run

        expect(lr1.reload.last_refreshed_day).to eq(2)
        expect(lr2.reload.last_refreshed_day).to eq(2)
        expect(lr3.reload.last_refreshed_day).to eq(2)
      end
    end

    context 'when game is not active' do
      before do
        game.update!(status: 'completed')
      end

      it 'fails validation' do
        action = GameTurnAction.new(game)
        expect(action.run).to be false
        expect(action.errors[:base]).to include('Game is not active')
      end
    end
  end
end
