require 'rails_helper'

RSpec.describe TravelAction, type: :service do
  let(:game) { create(:game, health: 10, current_day: 5) }
  let(:location1) { create(:location, x: 0, y: 0) }
  let(:location2) { create(:location, x: 1, y: 0) } # Adjacent to location1
  let(:location3) { create(:location, x: 2, y: 2) } # Far from location1

  before do
    game.update!(current_location_id: location1.id)
  end

  describe '#valid?' do
    context 'with valid params' do
      let(:action) { described_class.new(game, destination_id: location2.id) }

      it 'is valid' do
        expect(action).to be_valid
      end
    end

    context 'without destination_id' do
      let(:action) { described_class.new(game, destination_id: nil) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:destination_id]).to include("can't be blank")
      end
    end

    context 'with non-existent destination' do
      let(:action) { described_class.new(game, destination_id: 99999) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:destination_id]).to include("does not exist")
      end
    end

    context 'with same location as current' do
      let(:action) { described_class.new(game, destination_id: location1.id) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:destination_id]).to include("must be different from current location")
      end
    end

    context 'with non-adjacent location' do
      let(:action) { described_class.new(game, destination_id: location3.id) }

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:destination_id]).to include("is too far away (must be adjacent)")
      end
    end

    context 'with insufficient health' do
      let(:action) { described_class.new(game, destination_id: location2.id) }

      before do
        game.update!(health: 0)
      end

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:base]).to include("Game over: no health remaining")
      end
    end

    context 'with inactive game' do
      let(:action) { described_class.new(game, destination_id: location2.id) }

      before do
        game.update!(status: 'completed')
      end

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:base]).to include("Game is not active")
      end
    end
  end

  describe '#run' do
    let(:action) { described_class.new(game, destination_id: location2.id) }

    context 'with valid action' do
      it 'changes the current location' do
        expect {
          action.run
        }.to change { game.reload.current_location_id }.from(location1.id).to(location2.id)
      end

      it 'reduces health' do
        expect {
          action.run
        }.to change { game.reload.health }.by(-1)
      end

      it 'advances the day' do
        expect {
          action.run
        }.to change { game.reload.current_day }.by(1)
      end

      it 'increments locations_visited' do
        expect {
          action.run
        }.to change { game.reload.locations_visited }.by(1)
      end

      it 'returns success result' do
        result = action.run

        expect(result[:success]).to be true
        expect(result[:location]).to eq(location2)
        expect(result[:health_cost]).to eq(1)
        expect(result[:day_advanced]).to be true
      end
    end

    context 'when health drops to zero' do
      before do
        game.update!(health: 1)
      end

      it 'ends the game' do
        expect {
          action.run
        }.to change { game.reload.status }.from('active').to('game_over')
      end
    end

    context 'with invalid action' do
      let(:action) { described_class.new(game, destination_id: nil) }

      it 'raises an error' do
        expect {
          action.run
        }.to raise_error("Cannot run invalid action")
      end
    end
  end

  describe '#call' do
    context 'with valid params' do
      let(:action) { described_class.new(game, destination_id: location2.id) }

      it 'validates and runs the action' do
        expect(action.call).to be true
        expect(game.reload.current_location_id).to eq(location2.id)
      end
    end

    context 'with invalid params' do
      let(:action) { described_class.new(game, destination_id: nil) }

      it 'returns false without running' do
        expect(action.call).to be false
        expect(game.reload.current_location_id).to eq(location1.id)
      end
    end
  end
end
