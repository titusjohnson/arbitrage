# == Schema Information
#
# Table name: event_logs
#
#  id            :integer          not null, primary key
#  loggable_type :string
#  message       :text             not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  game_id       :integer          not null
#  loggable_id   :integer
#
# Indexes
#
#  index_event_logs_on_game_id                 (game_id)
#  index_event_logs_on_game_id_and_created_at  (game_id,created_at)
#  index_event_logs_on_loggable                (loggable_type,loggable_id)
#
# Foreign Keys
#
#  game_id  (game_id => games.id)
#
require 'rails_helper'

RSpec.describe EventLog, type: :model do
  describe 'associations' do
    it 'belongs to a game' do
      event_log = build(:event_log)
      expect(event_log.game).to be_present
    end

    it 'can optionally belong to a loggable' do
      event_log = build(:event_log, :without_loggable)
      expect(event_log.loggable).to be_nil
      expect(event_log).to be_valid
    end
  end

  describe 'validations' do
    it 'validates presence of message' do
      event_log = build(:event_log, message: nil)
      expect(event_log).not_to be_valid
      expect(event_log.errors[:message]).to include("can't be blank")
    end
  end

  describe 'scopes' do
    let(:game) { create(:game) }
    let!(:old_log) { create(:event_log, :without_loggable, game: game, created_at: 2.days.ago) }
    let!(:new_log) { create(:event_log, :without_loggable, game: game, created_at: 1.day.ago) }
    let(:other_game) { create(:game) }
    let!(:other_game_log) { create(:event_log, :without_loggable, game: other_game, created_at: 1.day.ago) }

    describe '.recent' do
      it 'returns logs in reverse chronological order' do
        all_logs = EventLog.recent.where(loggable_type: nil)
        expect(all_logs.to_a).to eq([other_game_log, new_log, old_log])
      end
    end

    describe '.chronological' do
      it 'returns logs in chronological order' do
        all_logs = EventLog.chronological.where(loggable_type: nil)
        expect(all_logs.to_a).to eq([old_log, new_log, other_game_log])
      end
    end

    describe '.for_game' do
      it 'returns only logs for the specified game' do
        game_logs = EventLog.for_game(game).where(loggable_type: nil)
        expect(game_logs).to match_array([old_log, new_log])
      end
    end
  end

  describe 'polymorphic associations' do
    let(:game) { create(:game) }

    context 'with a resource' do
      let(:resource) { create(:resource) }
      let(:event_log) { create(:event_log, :with_resource, game: game, loggable: resource) }

      it 'can associate with a resource' do
        expect(event_log.loggable).to eq(resource)
        expect(event_log.loggable_type).to eq('Resource')
      end
    end

    context 'with a location' do
      let(:location) { create(:location) }
      let(:event_log) { create(:event_log, :with_location, game: game, loggable: location) }

      it 'can associate with a location' do
        expect(event_log.loggable).to eq(location)
        expect(event_log.loggable_type).to eq('Location')
      end
    end

    context 'without a loggable' do
      let(:event_log) { create(:event_log, :without_loggable, game: game) }

      it 'can be created without a loggable association' do
        expect(event_log.loggable).to be_nil
        expect(event_log).to be_valid
      end
    end
  end
end
