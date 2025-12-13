require 'rails_helper'

RSpec.describe LocationVisit, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      visit = build(:location_visit)
      expect(visit).to be_valid
    end

    it 'is invalid without visited_on' do
      visit = build(:location_visit, visited_on: nil)
      expect(visit).not_to be_valid
      expect(visit.errors[:visited_on]).to include("can't be blank")
    end

    it 'validates visited_on is between 1 and 30' do
      game = create(:game)
      location = create(:location)

      visit = build(:location_visit, game: game, location: location, visited_on: 0)
      expect(visit).not_to be_valid
      expect(visit.errors[:visited_on]).to include("must be greater than or equal to 1")

      visit.visited_on = 31
      expect(visit).not_to be_valid
      expect(visit.errors[:visited_on]).to include("must be less than or equal to 30")

      visit.visited_on = 15
      expect(visit).to be_valid
    end
  end

  describe 'associations' do
    let(:visit) { build(:location_visit) }

    it 'belongs to a game' do
      expect(visit).to respond_to(:game)
    end

    it 'belongs to a location' do
      expect(visit).to respond_to(:location)
    end
  end

  describe 'scopes' do
    let(:game) { create(:game) }
    let(:location) { create(:location) }

    describe '.recent' do
      it 'returns visits from the last N days' do
        old_visit = create(:location_visit, game: game, location: location, visited_on: 5)
        recent_visit = create(:location_visit, game: game, location: location, visited_on: 15)

        recent_visits = LocationVisit.recent(10)
        expect(recent_visits).to include(recent_visit)
        expect(recent_visits).not_to include(old_visit)
      end
    end

    describe '.for_game' do
      it 'returns visits for a specific game' do
        game1_visit = create(:location_visit, game: game, location: location)
        game2 = create(:game)
        game2_visit = create(:location_visit, game: game2, location: location)

        game1_visits = LocationVisit.for_game(game)
        expect(game1_visits).to include(game1_visit)
        expect(game1_visits).not_to include(game2_visit)
      end
    end
  end
end
