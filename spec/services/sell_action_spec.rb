require 'rails_helper'

RSpec.describe SellAction, type: :service do
  let(:game) { create(:game, cash: 500.0) }
  let(:resource) { create(:resource) }

  describe '#valid?' do
    before do
      # Give the game some inventory to sell
      game.buy_resource(resource, 20, 10.0)
    end

    context 'with valid params' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 15.0) }

      it 'is valid' do
        expect(action).to be_valid
      end
    end

    context 'without resource_id' do
      let(:action) { described_class.new(game, resource_id: nil, quantity: 10, price_per_unit: 15.0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:resource_id]).to include("can't be blank")
      end
    end

    context 'with non-existent resource' do
      let(:action) { described_class.new(game, resource_id: 99999, quantity: 10, price_per_unit: 15.0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:resource_id]).to include("does not exist")
      end
    end

    context 'with zero quantity' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 0, price_per_unit: 15.0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:quantity]).to include("must be greater than 0")
      end
    end

    context 'with insufficient inventory' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 50, price_per_unit: 15.0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:inventory]).to include("not enough #{resource.name} (need 50, have 20)")
      end
    end

    context 'when player does not own the resource' do
      let(:other_resource) { create(:resource, name: "Other Resource") }
      let(:action) { described_class.new(game, resource_id: other_resource.id, quantity: 1, price_per_unit: 15.0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:inventory]).to include("not enough #{other_resource.name} (need 1, have 0)")
      end
    end
  end

  describe '#run' do
    let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 20.0) }

    before do
      # Buy 20 units at $10 each
      game.update!(cash: 500.0)
      game.buy_resource(resource, 20, 10.0)
      game.reload
    end

    context 'with valid action' do
      it 'removes items from inventory' do
        expect {
          action.run
        }.to change { game.inventory_items.where(resource: resource).sum(:quantity) }.from(20).to(10)
      end

      it 'adds cash to game' do
        initial_cash = game.cash
        action.run
        expect(game.reload.cash).to eq(initial_cash + 200.0)
      end

      it 'increments total_sales' do
        expect {
          action.run
        }.to change { game.reload.total_sales }.by(10)
      end

      it 'returns success result with profit calculation' do
        result = action.run

        expect(result[:success]).to be true
        expect(result[:resource]).to eq(resource)
        expect(result[:quantity]).to eq(10)
        expect(result[:total_revenue]).to eq(200.0)
        expect(result[:profit]).to eq(100.0) # Sold for $20, bought for $10 = $10 profit per unit
      end

      it 'updates best_deal_profit if this is a new record' do
        expect {
          action.run
        }.to change { game.reload.best_deal_profit }.from(0.0).to(100.0)
      end

      it 'does not update best_deal_profit if not a new record' do
        game.update!(best_deal_profit: 500.0)

        expect {
          action.run
        }.not_to change { game.reload.best_deal_profit }
      end
    end

    context 'with multiple inventory stacks at different prices (FIFO)' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 15, price_per_unit: 25.0) }

      before do
        # Already have 20 units at $10 from setup
        # Buy 10 more at $15
        game.buy_resource(resource, 10, 15.0)
        game.reload
      end

      it 'sells from oldest stack first (FIFO)' do
        action.run

        # Should have sold all 20 from first stack ($10) and 5 from second stack ($15)
        # Remaining should be 5 from second stack
        remaining = game.inventory_items.where(resource: resource).sum(:quantity)
        expect(remaining).to eq(15) # Started with 30, sold 15
      end

      it 'calculates profit correctly across stacks' do
        result = action.run

        # Sold 15 units for $25 each = $375 revenue
        # Cost: 10 units at $10 + 5 units at $15 = $100 + $75 = $175
        # Profit: $375 - $175 = $200
        expect(result[:profit]).to eq(200.0)
      end
    end

    context 'with invalid action' do
      let(:action) { described_class.new(game, resource_id: nil, quantity: 10, price_per_unit: 20.0) }

      it 'raises an error' do
        expect {
          action.run
        }.to raise_error("Cannot run invalid action")
      end
    end
  end

  describe '#call' do
    before do
      game.buy_resource(resource, 20, 10.0)
      game.reload
    end

    context 'with valid params' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 20.0) }

      it 'validates and runs the action' do
        initial_cash = game.cash
        expect(action.call).to be true
        expect(game.reload.cash).to eq(initial_cash + 200.0)
      end
    end

    context 'with invalid params' do
      let(:action) { described_class.new(game, resource_id: nil, quantity: 10, price_per_unit: 20.0) }

      it 'returns false without running' do
        initial_cash = game.cash
        expect(action.call).to be false
        expect(game.reload.cash).to eq(initial_cash)
      end
    end
  end
end
