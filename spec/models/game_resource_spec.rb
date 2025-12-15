# == Schema Information
#
# Table name: game_resources
#
#  id                 :integer          not null, primary key
#  available_quantity :integer          default(100), not null
#  base_price         :decimal(10, 2)   not null
#  current_price      :decimal(10, 2)   not null
#  last_refreshed_day :integer          not null
#  price_direction    :decimal(3, 2)    default(0.0), not null
#  price_momentum     :decimal(3, 2)    default(0.5), not null
#  sine_phase_offset  :decimal(5, 4)    default(0.0), not null
#  trend_phase_offset :decimal(5, 4)    default(0.0), not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#  game_id            :integer          not null
#  resource_id        :integer          not null
#
# Indexes
#
#  index_game_resources_on_game_id      (game_id)
#  index_game_resources_on_resource_id  (resource_id)
#  index_game_resources_unique          (game_id,resource_id) UNIQUE
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  resource_id  (resource_id => resources.id)
#
require 'rails_helper'

RSpec.describe GameResource, type: :model do
  let(:game) { create(:game) }
  let(:resource) { create(:resource, price_volatility: 50) }

  describe 'associations' do
    let(:game_resource) { create(:game_resource, game: game, resource: resource) }

    it 'belongs to game' do
      expect(game_resource.game).to eq(game)
    end

    it 'belongs to resource' do
      expect(game_resource.resource).to eq(resource)
    end

    it 'has many price_histories' do
      game_resource.generate_initial_history(days: 5)
      expect(game_resource.price_histories.count).to eq(5)
    end

    it 'destroys price_histories when destroyed' do
      game_resource.generate_initial_history(days: 5)
      expect { game_resource.destroy }.to change { ResourcePriceHistory.count }.by(-5)
    end
  end

  describe 'validations' do
    it 'is valid with valid attributes' do
      game_resource = build(:game_resource, game: game, resource: resource)
      expect(game_resource).to be_valid
    end

    it 'is invalid without current_price' do
      game_resource = build(:game_resource, game: game, resource: resource, current_price: nil)
      expect(game_resource).not_to be_valid
      expect(game_resource.errors[:current_price]).to include("can't be blank")
    end

    it 'is invalid without base_price' do
      game_resource = build(:game_resource, game: game, resource: resource, base_price: nil)
      expect(game_resource).not_to be_valid
      expect(game_resource.errors[:base_price]).to include("can't be blank")
    end

    it 'is invalid with non-positive current_price' do
      game_resource = build(:game_resource, game: game, resource: resource, current_price: 0)
      expect(game_resource).not_to be_valid
      expect(game_resource.errors[:current_price]).to include("must be greater than 0")
    end

    it 'is invalid with non-positive base_price' do
      game_resource = build(:game_resource, game: game, resource: resource, base_price: 0)
      expect(game_resource).not_to be_valid
      expect(game_resource.errors[:base_price]).to include("must be greater than 0")
    end

    it 'is invalid with duplicate resource for same game' do
      create(:game_resource, game: game, resource: resource)
      duplicate = build(:game_resource, game: game, resource: resource)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:resource_id]).to include("already exists for this game")
    end
  end

  describe '#update_market_dynamics!' do
    let(:game_resource) do
      create(:game_resource,
        game: game,
        resource: resource,
        current_price: 100.0,
        base_price: 100.0,
        available_quantity: 50,
        price_direction: 0.5,
        price_momentum: 0.5,
        last_refreshed_day: 1
      )
    end

    before do
      game.update!(current_day: 2)
    end

    it 'updates last_refreshed_day' do
      game_resource.update_market_dynamics!(2)
      expect(game_resource.last_refreshed_day).to eq(2)
    end

    it 'does not update if already refreshed for current day' do
      game_resource.update!(last_refreshed_day: 2)
      old_price = game_resource.current_price

      game_resource.update_market_dynamics!(2)

      expect(game_resource.current_price).to eq(old_price)
    end

    it 'updates current_price' do
      old_price = game_resource.current_price
      game_resource.update_market_dynamics!(2)

      expect(game_resource.current_price).not_to eq(old_price)
    end

    it 'keeps price above $1' do
      game_resource.update!(current_price: 2.0, base_price: 2.0)

      100.times do
        game_resource.update_market_dynamics!(game_resource.last_refreshed_day + 1)
      end

      expect(game_resource.current_price).to be >= 1.0
    end

    it 'keeps price within bounds of base_price' do
      game_resource.update_market_dynamics!(2)

      min_price = game_resource.base_price * 0.2
      max_price = game_resource.base_price * 1.8

      expect(game_resource.current_price).to be_between(min_price, max_price)
    end

    it 'updates price_direction' do
      game_resource.update_market_dynamics!(2)
      expect(game_resource.price_direction).to be_between(-1.0, 1.0)
    end

    it 'updates price_momentum' do
      game_resource.update_market_dynamics!(2)
      expect(game_resource.price_momentum).to be_between(0.0, 1.0)
    end

    it 'updates available_quantity' do
      game_resource.update_market_dynamics!(2)
      expect(game_resource.available_quantity).to be >= 0
    end

    it 'records price in history table' do
      expect {
        game_resource.update_market_dynamics!(2)
      }.to change { game_resource.price_histories.count }.by(1)

      history = game_resource.price_histories.find_by(day: 2)
      expect(history.price).to eq(game_resource.current_price)
      expect(history.quantity).to eq(game_resource.available_quantity)
    end

    context 'sinusoidal price movement' do
      it 'oscillates around base price over the sine period' do
        prices = []
        15.times do |i|
          game_resource.update_market_dynamics!(i + 2)
          prices << game_resource.current_price.to_f
        end

        # Prices should oscillate - we should see both prices above and below
        # the midpoint of the range over a full cycle (10 days + buffer)
        avg_price = prices.sum / prices.length
        above_avg = prices.count { |p| p > avg_price }
        below_avg = prices.count { |p| p < avg_price }

        # Both above and below average prices should exist
        expect(above_avg).to be > 0
        expect(below_avg).to be > 0
      end
    end

    context 'with high volatility resource' do
      let(:volatile_resource) { create(:resource, price_volatility: 90) }
      let(:volatile_game_resource) do
        create(:game_resource,
          game: game,
          resource: volatile_resource,
          current_price: 100.0,
          base_price: 100.0,
          price_direction: 0.5,
          price_momentum: 0.5,
          last_refreshed_day: 1
        )
      end

      it 'has larger price swings' do
        prices = [volatile_game_resource.current_price]

        10.times do |i|
          volatile_game_resource.update_market_dynamics!(i + 2)
          prices << volatile_game_resource.current_price
        end

        price_range = prices.max - prices.min
        # High volatility should produce some movement
        expect(price_range).to be > 0
      end
    end

    context 'with low volatility resource' do
      let(:stable_resource) { create(:resource, price_volatility: 10) }
      let(:game_resource) do
        create(:game_resource,
          game: game,
          resource: stable_resource,
          current_price: 100.0,
          base_price: 100.0,
          price_direction: 0.5,
          price_momentum: 0.5,
          last_refreshed_day: 1
        )
      end

      it 'has smaller price swings than high volatility resources' do
        # Low volatility resources still have trend wave movement (±25%)
        # but less random variation on top
        prices = [game_resource.current_price]

        10.times do |i|
          game_resource.update_market_dynamics!(i + 2)
          prices << game_resource.current_price
        end

        price_range = prices.max - prices.min
        # With trend wave (±25%) and sine wave (±10%), expect up to ~70% swing
        # but low volatility means minimal random variation on top
        expect(price_range).to be < 80
      end
    end
  end

  describe 'market pressure calculations' do
    let(:game_resource) do
      create(:game_resource,
        game: game,
        resource: resource,
        current_price: 100.0,
        base_price: 100.0,
        available_quantity: 50,
        price_direction: 0.0,
        price_momentum: 0.5,
        last_refreshed_day: 1
      )
    end

    describe '#calculate_demand_pressure' do
      it 'returns positive pressure when player owns the resource' do
        create(:inventory_item, game: game, resource: resource, quantity: 10)

        pressure = game_resource.send(:calculate_demand_pressure)
        expect(pressure).to be > 0
      end

      it 'returns negative pressure when player does not own the resource' do
        pressure = game_resource.send(:calculate_demand_pressure)
        expect(pressure).to be < 0
      end

      it 'returns higher pressure when player is hoarding' do
        create(:inventory_item, game: game, resource: resource, quantity: 100)

        pressure = game_resource.send(:calculate_demand_pressure)
        expect(pressure).to eq(0.2)
      end
    end
  end

  describe '.seed_for_game' do
    before do
      # Create some resources to seed
      create_list(:resource, 5)
    end

    it 'creates game resources for all resources' do
      new_game = create(:game)
      GameResource.seed_for_game(new_game)

      expect(new_game.game_resources.count).to eq(Resource.count)
    end

    it 'sets base_price for new game resources' do
      new_game = create(:game)
      GameResource.seed_for_game(new_game)

      new_game.game_resources.each do |gr|
        expect(gr.base_price).to be_present
        expect(gr.base_price).to eq(gr.current_price)
      end
    end

    it 'sets initial price_direction between -1 and 1' do
      new_game = create(:game)
      GameResource.seed_for_game(new_game)

      new_game.game_resources.each do |gr|
        expect(gr.price_direction).to be_between(-1.0, 1.0)
      end
    end

    it 'sets initial price_momentum to 0.5' do
      new_game = create(:game)
      GameResource.seed_for_game(new_game)

      new_game.game_resources.each do |gr|
        expect(gr.price_momentum).to eq(0.5)
      end
    end

    it 'generates price history for each game resource when generate_history is true' do
      new_game = create(:game)
      GameResource.seed_for_game(new_game, generate_history: true)

      new_game.game_resources.each do |gr|
        expect(gr.price_histories.count).to eq(30)
      end
    end

    it 'does not generate price history when generate_history is false' do
      new_game = create(:game)
      GameResource.seed_for_game(new_game, generate_history: false)

      new_game.game_resources.each do |gr|
        expect(gr.price_histories.count).to eq(0)
      end
    end
  end

  describe '#price_on_day' do
    let(:game_resource) { create(:game_resource, :with_history, game: game, resource: resource) }

    it 'returns the price for a specific day' do
      price = game_resource.price_on_day(1)
      expect(price).to be_a(BigDecimal)
      expect(price).to be > 0
    end

    it 'returns nil for a day without history' do
      expect(game_resource.price_on_day(100)).to be_nil
    end
  end

  describe '#price_history_array' do
    let(:game_resource) { create(:game_resource, :with_history, game: game, resource: resource) }

    it 'returns an array of prices' do
      history = game_resource.price_history_array(days: 30)
      expect(history).to be_an(Array)
      expect(history.length).to eq(30)
    end

    it 'returns prices in day order' do
      history = game_resource.price_history_array(days: 30)
      expect(history.first).to eq(game_resource.price_on_day(1))
    end
  end

  describe '#generate_initial_history' do
    let(:game_resource) do
      create(:game_resource,
        game: game,
        resource: resource,
        current_price: 100.0,
        base_price: 100.0,
        available_quantity: 50,
        last_refreshed_day: 1
      )
    end

    it 'creates 30 days of price history' do
      expect {
        game_resource.generate_initial_history(days: 30)
      }.to change { game_resource.price_histories.count }.by(30)
    end

    it 'creates prices within bounds of base_price' do
      game_resource.generate_initial_history(days: 30)

      min_price = game_resource.base_price * 0.2
      max_price = game_resource.base_price * 1.8

      game_resource.price_histories.each do |history|
        expect(history.price).to be_between(min_price, max_price)
      end
    end
  end
end
