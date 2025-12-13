require 'rails_helper'

RSpec.describe BuyAction, type: :service do
  let(:game) { create(:game, cash: 1000.0, inventory_capacity: 100) }
  let(:resource) { create(:resource, inventory_size: 5) }

  describe '#valid?' do
    context 'with valid params' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 15.50) }

      it 'is valid' do
        expect(action).to be_valid
      end
    end

    context 'without resource_id' do
      let(:action) { described_class.new(game, resource_id: nil, quantity: 10, price_per_unit: 15.50) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:resource_id]).to include("can't be blank")
      end
    end

    context 'with non-existent resource' do
      let(:action) { described_class.new(game, resource_id: 99999, quantity: 10, price_per_unit: 15.50) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:resource_id]).to include("does not exist")
      end
    end

    context 'with zero quantity' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 0, price_per_unit: 15.50) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:quantity]).to include("must be greater than 0")
      end
    end

    context 'with negative quantity' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: -5, price_per_unit: 15.50) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:quantity]).to include("must be greater than 0")
      end
    end

    context 'with zero price' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:price_per_unit]).to include("must be greater than 0")
      end
    end

    context 'with insufficient cash' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 100, price_per_unit: 15.50) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:cash]).to include("insufficient funds (need 1550.0, have 1000.0)")
      end
    end

    context 'with insufficient inventory space' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 25, price_per_unit: 10.0) }
      # 25 units * 5 size = 125 space needed, but only 100 available

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:inventory]).to include("insufficient space (need 125, have 100)")
      end
    end
  end

  describe '#run' do
    let(:location) { create(:location) }
    let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 15.50) }

    before do
      game.update!(current_location_id: location.id)
    end

    context 'with valid action' do
      it 'creates an inventory item' do
        expect {
          action.run
        }.to change { game.inventory_items.count }.by(1)
      end

      it 'deducts cash from game' do
        expect {
          action.run
        }.to change { game.reload.cash }.by(-155.0)
      end

      it 'increments total_purchases' do
        expect {
          action.run
        }.to change { game.reload.total_purchases }.by(10)
      end

      it 'returns success result' do
        result = action.run

        expect(result[:success]).to be true
        expect(result[:resource]).to eq(resource)
        expect(result[:quantity]).to eq(10)
        expect(result[:total_cost]).to eq(155.0)
      end

      it 'stores the correct purchase price' do
        action.run
        item = game.inventory_items.last

        expect(item.purchase_price).to eq(15.50)
        expect(item.quantity).to eq(10)
      end
    end

    context 'with invalid action' do
      let(:action) { described_class.new(game, resource_id: nil, quantity: 10, price_per_unit: 15.50) }

      it 'raises an error' do
        expect {
          action.run
        }.to raise_error("Cannot run invalid action")
      end
    end
  end

  describe '#call' do
    context 'with valid params' do
      let(:action) { described_class.new(game, resource_id: resource.id, quantity: 10, price_per_unit: 15.50) }

      it 'validates and runs the action' do
        expect(action.call).to be true
        expect(game.reload.cash).to eq(845.0)
      end
    end

    context 'with invalid params' do
      let(:action) { described_class.new(game, resource_id: nil, quantity: 10, price_per_unit: 15.50) }

      it 'returns false without running' do
        expect(action.call).to be false
        expect(game.reload.cash).to eq(1000.0)
      end
    end
  end
end
