# == Schema Information
#
# Table name: locations
#
#  id          :integer          not null, primary key
#  description :text
#  name        :string           not null
#  population  :integer          default(0), not null
#  x           :integer          not null
#  y           :integer          not null
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#
# Indexes
#
#  index_locations_on_x_and_y  (x,y) UNIQUE
#
require 'rails_helper'

RSpec.describe Location, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      location = build(:location)
      expect(location).to be_valid
    end

    it 'is invalid without a name' do
      location = build(:location, name: nil)
      expect(location).not_to be_valid
      expect(location.errors[:name]).to include("can't be blank")
    end

    it 'validates uniqueness of x scoped to y' do
      create(:location, x: 1, y: 1)
      duplicate = build(:location, x: 1, y: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:x]).to include("and y coordinates must be unique")
    end
  end

  describe 'associations' do
    let(:location) { create(:location) }

    it 'has many location_resources' do
      expect(location).to respond_to(:location_resources)
    end

    it 'has many location_visits' do
      expect(location).to respond_to(:location_visits)
    end
  end

  describe '#distance_to' do
    let(:location1) { create(:location, x: 0, y: 0) }
    let(:location2) { create(:location, x: 2, y: 3) }

    it 'calculates Manhattan distance correctly' do
      expect(location1.distance_to(location2)).to eq(5)
    end

    it 'returns 0 for same location' do
      expect(location1.distance_to(location1)).to eq(0)
    end
  end

  describe '#coordinates' do
    let(:location) { create(:location, x: 3, y: 2) }

    it 'returns coordinates as a tuple' do
      expect(location.coordinates).to eq([3, 2])
    end
  end

  describe '#neighbors' do
    let!(:center) { create(:location, x: 2, y: 2) }
    let!(:north) { create(:location, x: 2, y: 1) }
    let!(:south) { create(:location, x: 2, y: 3) }
    let!(:east) { create(:location, x: 3, y: 2) }
    let!(:west) { create(:location, x: 1, y: 2) }
    let!(:diagonal) { create(:location, x: 3, y: 3) }

    it 'returns adjacent locations (up, down, left, right)' do
      neighbors = center.neighbors
      expect(neighbors).to include(north, south, east, west)
      expect(neighbors).not_to include(diagonal)
      expect(neighbors.count).to eq(4)
    end
  end
end
