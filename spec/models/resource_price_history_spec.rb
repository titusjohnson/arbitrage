# == Schema Information
#
# Table name: resource_price_histories
#
#  id               :integer          not null, primary key
#  day              :integer          not null
#  price            :decimal(10, 2)   not null
#  quantity         :integer          not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  game_resource_id :integer          not null
#
# Indexes
#
#  index_price_histories_for_analysis  (game_resource_id,day,price)
#  index_price_histories_unique        (game_resource_id,day) UNIQUE
#
# Foreign Keys
#
#  game_resource_id  (game_resource_id => game_resources.id)
#
require 'rails_helper'

RSpec.describe ResourcePriceHistory, type: :model do
  let(:game) { create(:game) }
  let(:resource) { create(:resource) }
  let(:game_resource) { create(:game_resource, game: game, resource: resource) }

  describe 'associations' do
    it 'belongs to game_resource' do
      history = create(:resource_price_history, game_resource: game_resource)
      expect(history.game_resource).to eq(game_resource)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      history = build(:resource_price_history, game_resource: game_resource)
      expect(history).to be_valid
    end

    it 'is invalid without day' do
      history = build(:resource_price_history, game_resource: game_resource, day: nil)
      expect(history).not_to be_valid
      expect(history.errors[:day]).to include("can't be blank")
    end

    it 'is invalid without price' do
      history = build(:resource_price_history, game_resource: game_resource, price: nil)
      expect(history).not_to be_valid
      expect(history.errors[:price]).to include("can't be blank")
    end

    it 'is invalid without quantity' do
      history = build(:resource_price_history, game_resource: game_resource, quantity: nil)
      expect(history).not_to be_valid
      expect(history.errors[:quantity]).to include("can't be blank")
    end

    it 'is invalid with non-positive price' do
      history = build(:resource_price_history, game_resource: game_resource, price: 0)
      expect(history).not_to be_valid
      expect(history.errors[:price]).to include("must be greater than 0")
    end

    it 'is invalid with negative quantity' do
      history = build(:resource_price_history, game_resource: game_resource, quantity: -1)
      expect(history).not_to be_valid
      expect(history.errors[:quantity]).to include("must be greater than or equal to 0")
    end

    it 'validates uniqueness of day within game_resource scope' do
      create(:resource_price_history, game_resource: game_resource, day: 1)
      duplicate = build(:resource_price_history, game_resource: game_resource, day: 1)

      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:day]).to include('has already been taken')
    end
  end

  describe 'scopes' do
    before do
      (1..10).each do |day|
        create(:resource_price_history, game_resource: game_resource, day: day, price: 100 + day)
      end
    end

    describe '.for_day' do
      it 'returns records for a specific day' do
        records = described_class.for_day(5)
        expect(records.count).to eq(1)
        expect(records.first.day).to eq(5)
      end
    end

    describe '.between_days' do
      it 'returns records within a day range' do
        records = described_class.between_days(3, 7)
        expect(records.count).to eq(5)
        expect(records.pluck(:day)).to match_array([3, 4, 5, 6, 7])
      end
    end

    describe '.ordered' do
      it 'returns records ordered by day' do
        records = described_class.ordered
        expect(records.pluck(:day)).to eq((1..10).to_a)
      end
    end
  end
end
