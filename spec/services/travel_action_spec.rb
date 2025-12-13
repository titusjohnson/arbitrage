require 'rails_helper'

RSpec.describe TravelAction, type: :service do
  let(:location1) { create(:location, x: 0, y: 0) }
  let(:location2) { create(:location, x: 1, y: 0) } # Adjacent to location1
  let(:location3) { create(:location, x: 2, y: 2) } # Far from location1
  let(:game) { create(:game, cash: 1000, current_day: 5, current_location: location1) }

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

    context 'with insufficient cash' do
      let(:action) { described_class.new(game, destination_id: location2.id) }

      before do
        game.update!(cash: 50) # Not enough for $100 travel cost
      end

      it 'is invalid' do
        expect(action).not_to be_valid
        expect(action.errors[:base]).to include("Not enough cash for this journey (need $100, have $50.0)")
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

      it 'reduces cash by $100' do
        expect {
          action.run
        }.to change { game.reload.cash }.by(-100)
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

      it 'creates an event log' do
        expect {
          action.run
        }.to change { game.reload.event_logs.count }.by(1)
      end

      it 'logs the travel message' do
        action.run
        log = game.reload.event_logs.last
        expect(log.message).to eq("Traveled to #{location2.name}")
      end

      it 'associates the log with the destination location' do
        action.run
        log = game.reload.event_logs.last
        expect(log.loggable).to eq(location2)
      end

      it 'stores the log in the action instance' do
        action.run
        expect(action.instance_variable_get(:@log)).to be_a(EventLog)
        expect(action.instance_variable_get(:@log).message).to match("Traveled to #{location2.name}")
      end

      it 'returns true' do
        expect(action.run).to be true
      end
    end

    context 'with invalid action' do
      let(:action) { described_class.new(game, destination_id: nil) }

      it 'returns false' do
        expect(action.run).to be false
      end

      it 'does not create an event log' do
        expect {
          action.run
        }.not_to change { game.reload.event_logs.count }
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
