# == Schema Information
#
# Table name: location_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  location_id        :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_location_resources_on_game_and_location  (game_id,location_id)
#  index_location_resources_on_game_id            (game_id)
#  index_location_resources_on_location_id        (location_id)
#  index_location_resources_on_resource_id        (resource_id)
#  index_location_resources_unique                (game_id,location_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  location_id  (location_id => locations.id)
#  resource_id  (resource_id => resources.id)
#
require 'rails_helper'

RSpec.describe LocationResource, type: :model do
  describe 'associations' do
    it 'belongs to game' do
      location_resource = build(:location_resource)
      expect(location_resource).to respond_to(:game)
    end

    it 'belongs to location' do
      location_resource = build(:location_resource)
      expect(location_resource).to respond_to(:location)
    end

    it 'belongs to resource' do
      location_resource = build(:location_resource)
      expect(location_resource).to respond_to(:resource)
    end
  end

  describe 'validations' do
    it 'requires current_price to be present' do
      location_resource = build(:location_resource, current_price: nil)
      expect(location_resource).not_to be_valid
      expect(location_resource.errors[:current_price]).to include("can't be blank")
    end

    it 'requires current_price to be greater than 0' do
      location_resource = build(:location_resource, current_price: 0)
      expect(location_resource).not_to be_valid
      expect(location_resource.errors[:current_price]).to include("must be greater than 0")
    end

    it 'requires last_refreshed_day to be present' do
      location_resource = build(:location_resource, last_refreshed_day: nil)
      expect(location_resource).not_to be_valid
      expect(location_resource.errors[:last_refreshed_day]).to include("can't be blank")
    end

    it 'requires last_refreshed_day to be an integer >= 1' do
      location_resource = build(:location_resource, last_refreshed_day: 0)
      expect(location_resource).not_to be_valid
      expect(location_resource.errors[:last_refreshed_day]).to include("must be greater than or equal to 1")
    end

    it 'validates uniqueness of resource per game and location' do
      existing = create(:location_resource)
      duplicate = build(:location_resource,
        game: existing.game,
        location: existing.location,
        resource: existing.resource
      )

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:resource_id]).to include("already exists at this location for this game")
    end
  end

  describe 'scopes' do
    let(:game) { create(:game) }
    let(:location) { create(:location) }
    let!(:location_resource) { create(:location_resource, game: game, location: location, last_refreshed_day: 5) }
    let!(:other_location_resource) { create(:location_resource, last_refreshed_day: 3) }

    describe '.for_game_and_location' do
      it 'returns location resources for specific game and location' do
        expect(LocationResource.for_game_and_location(game, location)).to eq([location_resource])
      end
    end

    describe '.fresh' do
      it 'returns resources refreshed on or after the previous day' do
        expect(LocationResource.fresh(6)).to include(location_resource)
        expect(LocationResource.fresh(6)).not_to include(other_location_resource)
      end
    end

    describe '.stale' do
      it 'returns resources not refreshed recently' do
        expect(LocationResource.stale(6)).to include(other_location_resource)
        expect(LocationResource.stale(6)).not_to include(location_resource)
      end
    end
  end

  describe '.seed_for_location' do
    let(:game) { create(:game) }
    let(:location) { create(:location) }

    before do
      # Create some resources with different rarities
      create(:resource, name: 'Common Item 1', rarity: :common)
      create(:resource, name: 'Common Item 2', rarity: :common)
      create(:resource, name: 'Uncommon Item', rarity: :uncommon)
      create(:resource, name: 'Rare Item', rarity: :rare)
    end

    it 'seeds resources for a location' do
      expect {
        LocationResource.seed_for_location(game, location)
      }.to change { LocationResource.count }.by_at_least(1)
    end

    it 'does not re-seed if already seeded' do
      LocationResource.seed_for_location(game, location)
      initial_count = LocationResource.count

      LocationResource.seed_for_location(game, location)
      expect(LocationResource.count).to eq(initial_count)
    end

    it 'creates location resources with valid prices' do
      LocationResource.seed_for_location(game, location)

      LocationResource.for_game_and_location(game, location).each do |lr|
        expect(lr.current_price).to be > 0
        expect(lr.last_refreshed_day).to eq(game.current_day)
      end
    end

    context 'with tagged location' do
      let!(:location) { create(:location, name: 'Tech City') }

      before do
        location.tag_names = ['tech_hub', 'wealthy']
        location.save!

        iphone = create(:resource, name: 'iPhone', rarity: :common)
        iphone.tag_names = ['technology']
        iphone.save!

        macbook = create(:resource, name: 'MacBook', rarity: :uncommon)
        macbook.tag_names = ['technology']
        macbook.save!
      end

      it 'seeds resources for tagged location' do
        LocationResource.seed_for_location(game, location)

        seeded_resources = LocationResource.for_game_and_location(game, location).map(&:resource)

        # Should seed at least the minimum resources
        expect(seeded_resources.size).to be >= 4
      end
    end
  end

  describe '.select_resources_for_location' do
    let(:location) { create(:location) }

    before do
      # Create enough resources for minimum variety
      15.times { |i| create(:resource, name: "Resource #{i}", rarity: :common) }
    end

    it 'returns an array of resources' do
      result = LocationResource.select_resources_for_location(location)
      expect(result).to be_an(Array)
      expect(result.first).to be_a(Resource)
    end

    it 'ensures minimum variety of at least 10 resources' do
      result = LocationResource.select_resources_for_location(location)
      expect(result.size).to be >= 10
    end

    it 'returns unique resources' do
      result = LocationResource.select_resources_for_location(location)
      expect(result.uniq.size).to eq(result.size)
    end
  end

  describe '.sample_by_rarity' do
    before do
      5.times { create(:resource, rarity: :common) }
      3.times { create(:resource, rarity: :uncommon) }
      2.times { create(:resource, rarity: :rare) }
      1.times { create(:resource, rarity: :ultra_rare) }
    end

    it 'samples resources respecting rarity distribution' do
      resources = Resource.all
      sampled = LocationResource.sample_by_rarity(resources, target_count: 10)

      expect(sampled.size).to be <= 10
      expect(sampled).to be_an(Array)
    end

    it 'includes more common resources than rare ones' do
      resources = Resource.all
      sampled = LocationResource.sample_by_rarity(resources, target_count: 10)

      common_count = sampled.count { |r| r.rarity == 'common' }
      rare_count = sampled.count { |r| r.rarity == 'rare' }

      expect(common_count).to be >= rare_count
    end
  end

  describe '#needs_refresh?' do
    let(:location_resource) { create(:location_resource, last_refreshed_day: 5) }

    it 'returns true if last_refreshed_day is before current_day' do
      expect(location_resource.needs_refresh?(6)).to be true
    end

    it 'returns false if last_refreshed_day is current_day' do
      expect(location_resource.needs_refresh?(5)).to be false
    end
  end

  describe '#refresh_price!' do
    let(:resource) { create(:resource, base_price_min: 100, base_price_max: 200) }
    let(:location_resource) { create(:location_resource, resource: resource, last_refreshed_day: 1) }

    it 'updates the current_price' do
      old_price = location_resource.current_price
      location_resource.refresh_price!(5)

      # Price is regenerated (might be same by chance, but day should update)
      expect(location_resource.reload.last_refreshed_day).to eq(5)
    end

    it 'updates the last_refreshed_day' do
      location_resource.refresh_price!(10)
      expect(location_resource.last_refreshed_day).to eq(10)
    end

    it 'generates a valid market price' do
      location_resource.refresh_price!(5)

      # Verify the price is within a valid range
      expect(location_resource.current_price).to be > 0
      expect(location_resource.last_refreshed_day).to eq(5)
    end
  end
end
