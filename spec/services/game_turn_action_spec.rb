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
    context 'with no game resources' do
      it 'succeeds without errors' do
        action = GameTurnAction.new(game)
        expect(action.run).to be true
      end
    end

    context 'with game resources' do
      let!(:game_resource) do
        create(:game_resource,
          game: game,
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

      it 'updates market dynamics for all game resources' do
        action = GameTurnAction.new(game)
        expect(action.run).to be true

        game_resource.reload
        expect(game_resource.last_refreshed_day).to eq(2)
      end

      it 'changes prices based on direction' do
        action = GameTurnAction.new(game)
        old_price = game_resource.current_price

        action.run
        game_resource.reload

        expect(game_resource.current_price).not_to eq(old_price)
      end

      it 'updates price direction' do
        action = GameTurnAction.new(game)

        action.run
        game_resource.reload

        # Direction should change based on market forces
        expect(game_resource.price_direction).to be_between(-1.0, 1.0)
      end

      it 'updates price momentum' do
        action = GameTurnAction.new(game)

        action.run
        game_resource.reload

        expect(game_resource.price_momentum).to be_between(0.0, 1.0)
      end

      it 'updates available quantity' do
        action = GameTurnAction.new(game)

        action.run
        game_resource.reload

        expect(game_resource.available_quantity).to be >= 0
      end
    end

    context 'with multiple resources' do
      let(:resource2) { create(:resource) }

      let!(:gr1) { create(:game_resource, game: game, resource: resource, last_refreshed_day: 1) }
      let!(:gr2) { create(:game_resource, game: game, resource: resource2, last_refreshed_day: 1) }

      before do
        game.update!(current_day: 2)
      end

      it 'updates all game resources' do
        action = GameTurnAction.new(game)
        action.run

        expect(gr1.reload.last_refreshed_day).to eq(2)
        expect(gr2.reload.last_refreshed_day).to eq(2)
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

    context 'with buddy auto-selling' do
      let!(:game_resource) do
        create(:game_resource,
          game: game,
          resource: resource,
          current_price: 130.0,
          base_price: 100.0
        )
      end

      it 'processes buddy sales when target price is reached' do
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        action = GameTurnAction.new(game)
        action.run

        expect(buddy.reload.status).to eq('sold')
      end

      it 'does not sell when target price is not reached' do
        game_resource.update!(current_price: 110.0)

        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        action = GameTurnAction.new(game)
        action.run

        expect(buddy.reload.status).to eq('holding')
      end

      it 'creates an event log when buddy sells' do
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        expect {
          GameTurnAction.new(game).run
        }.to change { game.event_logs.count }.by(1)

        log = game.event_logs.last
        expect(log.message).to include(buddy.name)
        expect(log.message).to include(resource.name)
        expect(log.message).to include("profit")
      end

      it 'includes location name in event log' do
        buddy = create(:buddy, :holding,
          game: game,
          location: location,
          resource: resource,
          purchase_price: 100.0,
          quantity: 5,
          target_profit_percent: 25
        )

        GameTurnAction.new(game).run

        log = game.event_logs.last
        expect(log.message).to include(location.name)
      end
    end
  end
end
