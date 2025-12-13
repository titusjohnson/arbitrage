require 'rails_helper'

RSpec.describe BuyAction, type: :service do
  let(:game) { create(:game, cash: 1000.0, inventory_capacity: 100) }
  let(:location) { create(:location) }
  let(:resource) { create(:resource, inventory_size: 5) }
  let(:location_resource) { create(:location_resource, location: location, resource: resource, current_price: 15.50) }

  before do
    game.update!(current_location_id: location.id)
  end

  describe '#valid?' do
    context 'with valid params' do
      let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: 10) }

      it 'is valid' do
        expect(action).to be_valid
      end
    end

    context 'without location_resource_id' do
      let(:action) { described_class.new(game, location_resource_id: nil, quantity: 10) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:location_resource_id]).to include("can't be blank")
      end
    end

    context 'with non-existent location_resource' do
      let(:action) { described_class.new(game, location_resource_id: 99999, quantity: 10) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:location_resource_id]).to include("does not exist")
      end
    end

    context 'with zero quantity' do
      let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: 0) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:quantity]).to include("must be greater than 0")
      end
    end

    context 'with negative quantity' do
      let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: -5) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:quantity]).to include("must be greater than 0")
      end
    end

    context 'with insufficient cash' do
      let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: 100) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:cash]).to include("insufficient funds (need 1550.0, have 1000.0)")
      end
    end

    context 'with insufficient inventory space' do
      let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: 25) }
      # 25 units * 5 size = 125 space needed, but only 100 available

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:inventory]).to include("insufficient space (need 125, have 100)")
      end
    end
  end

  describe '#run' do
    let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: 10) }

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

      it 'returns true on success' do
        expect(action.run).to be true
      end

      it 'stores the correct purchase price' do
        action.run
        item = game.inventory_items.last

        expect(item.purchase_price).to eq(15.50)
        expect(item.quantity).to eq(10)
      end
    end

    context 'with invalid action' do
      let(:action) { described_class.new(game, location_resource_id: nil, quantity: 10) }

      it 'returns false' do
        expect(action.run).to be false
      end
    end
  end

  describe '#call' do
    context 'with valid params' do
      let(:action) { described_class.new(game, location_resource_id: location_resource.id, quantity: 10) }

      it 'validates and runs the action' do
        expect(action.call).to be true
        expect(game.reload.cash).to eq(845.0)
      end
    end

    context 'with invalid params' do
      let(:action) { described_class.new(game, location_resource_id: nil, quantity: 10) }

      it 'returns false without running' do
        expect(action.call).to be false
        expect(game.reload.cash).to eq(1000.0)
      end
    end
  end
end
