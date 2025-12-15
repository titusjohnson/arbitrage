require 'rails_helper'

RSpec.describe MarketAnalysisService do
  let(:game) { create(:game, current_day: 10) }
  let(:resource) { create(:resource) }

  describe '#significant_movers' do
    context 'with price movements above threshold' do
      it 'identifies resources with significant price increases' do
        # Create a game resource with price history showing 50% increase
        game_resource = create(:game_resource,
          game: game,
          resource: resource,
          current_price: 150.0
        )
        # Create price history for day 3 (lookback point)
        create(:resource_price_history, game_resource: game_resource, day: 3, price: 100.0, quantity: 50)

        service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
        movers = service.significant_movers

        expect(movers).not_to be_empty
        expect(movers.first[:resource]).to eq(resource)
        expect(movers.first[:change_percent]).to eq(50.0)
        expect(movers.first[:direction]).to eq(:increase)
      end

      it 'identifies resources with significant price decreases' do
        game_resource = create(:game_resource,
          game: game,
          resource: resource,
          current_price: 50.0
        )
        create(:resource_price_history, game_resource: game_resource, day: 3, price: 100.0, quantity: 50)

        service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
        movers = service.significant_movers

        expect(movers).not_to be_empty
        expect(movers.first[:change_percent]).to eq(-50.0)
        expect(movers.first[:direction]).to eq(:decrease)
      end
    end

    context 'with price movements below threshold' do
      it 'excludes resources with small price changes' do
        game_resource = create(:game_resource,
          game: game,
          resource: resource,
          current_price: 110.0
        )
        create(:resource_price_history, game_resource: game_resource, day: 3, price: 100.0, quantity: 50)

        service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
        movers = service.significant_movers

        expect(movers).to be_empty
      end
    end

    context 'with custom threshold' do
      it 'respects the configured threshold' do
        game_resource = create(:game_resource,
          game: game,
          resource: resource,
          current_price: 105.0
        )
        create(:resource_price_history, game_resource: game_resource, day: 3, price: 100.0, quantity: 50)

        # 5% change should be caught with 0.05 threshold
        service = MarketAnalysisService.new(game, threshold: 0.05, days_back: 7)
        movers = service.significant_movers

        expect(movers).not_to be_empty
        expect(movers.first[:change_percent]).to eq(5.0)
      end
    end

    context 'with limit parameter' do
      it 'limits the number of results returned' do
        # Use a fresh game without auto-seeding for this test
        fresh_game = create(:game, current_day: 10)

        3.times do
          r = create(:resource)
          gr = create(:game_resource,
            game: fresh_game,
            resource: r,
            current_price: 200.0
          )
          create(:resource_price_history, game_resource: gr, day: 3, price: 100.0, quantity: 50)
        end

        service = MarketAnalysisService.new(fresh_game, threshold: 0.20, days_back: 7)
        movers = service.significant_movers(limit: 2)

        expect(movers.length).to eq(2)
      end
    end

    context 'with missing or invalid price history' do
      it 'handles resources without price history' do
        create(:game_resource,
          game: game,
          resource: resource,
          current_price: 150.0
        )
        # No price history created

        service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
        movers = service.significant_movers

        expect(movers).to be_empty
      end

      it 'handles resources without historical price for the lookback period' do
        game_resource = create(:game_resource,
          game: game,
          resource: resource,
          current_price: 150.0
        )
        # Day 1 only, but we're on day 10 looking back 7 days (to day 3)
        create(:resource_price_history, game_resource: game_resource, day: 1, price: 100.0, quantity: 50)

        service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
        movers = service.significant_movers

        expect(movers).to be_empty
      end
    end

    it 'sorts movers by absolute change percentage' do
      # Use a fresh game to avoid interference from other tests
      fresh_game = create(:game, current_day: 10)

      # Create resources with different change percentages
      resource1 = create(:resource)
      resource2 = create(:resource)
      resource3 = create(:resource)

      gr1 = create(:game_resource,
        game: fresh_game,
        resource: resource1,
        current_price: 130.0
      )
      create(:resource_price_history, game_resource: gr1, day: 3, price: 100.0, quantity: 50) # 30% increase

      gr2 = create(:game_resource,
        game: fresh_game,
        resource: resource2,
        current_price: 200.0
      )
      create(:resource_price_history, game_resource: gr2, day: 3, price: 100.0, quantity: 50) # 100% increase

      gr3 = create(:game_resource,
        game: fresh_game,
        resource: resource3,
        current_price: 40.0
      )
      create(:resource_price_history, game_resource: gr3, day: 3, price: 100.0, quantity: 50) # -60% decrease

      service = MarketAnalysisService.new(fresh_game, threshold: 0.20, days_back: 7)
      movers = service.significant_movers

      expect(movers.length).to eq(3)
      expect(movers[0][:change_percent]).to eq(100.0)
      expect(movers[1][:change_percent]).to eq(-60.0)
      expect(movers[2][:change_percent]).to eq(30.0)
    end
  end

  describe 'return structure' do
    it 'returns properly structured data' do
      game_resource = create(:game_resource,
        game: game,
        resource: resource,
        current_price: 150.0
      )
      create(:resource_price_history, game_resource: game_resource, day: 3, price: 100.0, quantity: 50)

      service = MarketAnalysisService.new(game, threshold: 0.20, days_back: 7)
      movers = service.significant_movers

      mover = movers.first
      expect(mover).to include(
        :game_resource,
        :resource,
        :old_price,
        :current_price,
        :change_percent,
        :direction
      )

      expect(mover[:game_resource]).to eq(game_resource)
      expect(mover[:resource]).to eq(resource)
      expect(mover[:old_price]).to eq(100.0)
      expect(mover[:current_price]).to eq(150.0)
    end
  end
end
