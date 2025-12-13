require 'rails_helper'

# == Schema Information
#
# Table name: games
#
#  id                 :integer          not null, primary key
#  current_day        :integer          default(1), not null
#  current_location_id:integer
#  cash               :decimal(10, 2)   default(2000.0), not null
#  bank_balance       :decimal(10, 2)   default(0.0), not null
#  debt               :decimal(10, 2)   default(0.0), not null
#  status             :string           default("active"), not null
#  final_score        :integer
#  health             :integer          default(10), not null
#  max_health         :integer          default(10), not null
#  inventory_capacity :integer          default(100), not null
#  started_at         :datetime         not null
#  completed_at       :datetime
#  total_purchases    :integer          default(0), not null
#  total_sales        :integer          default(0), not null
#  locations_visited  :integer          default(1), not null
#  best_deal_profit   :decimal(10, 2)   default(0.0), not null
#  restore_key        :string           not null
#  created_at         :datetime         not null
#  updated_at         :datetime         not null
#
# Indexes
#
#  index_games_on_restore_key  (restore_key) UNIQUE
#  index_games_on_started_at   (started_at)
#  index_games_on_status       (status)
#
RSpec.describe Game, type: :model do
  describe "scopes" do
    let!(:active_game) { create(:game, status: "active") }
    let!(:completed_game) { create(:game, :completed) }
    let!(:game_over_game) { create(:game, :game_over) }

    describe ".active" do
      it "returns only active games" do
        expect(Game.active).to eq([ active_game ])
      end
    end

    describe ".completed" do
      it "returns only completed games" do
        expect(Game.completed).to eq([ completed_game ])
      end
    end

    describe ".game_over" do
      it "returns only game over games" do
        expect(Game.game_over).to eq([ game_over_game ])
      end
    end

    describe ".finished" do
      it "returns both completed and game over games" do
        expect(Game.finished).to match_array([ completed_game, game_over_game ])
      end
    end

    describe ".recent" do
      it "orders games by started_at descending" do
        older_game = create(:game, started_at: 2.days.ago)
        newer_game = create(:game, started_at: 1.day.ago)

        recent_games = Game.recent.to_a
        expect(recent_games.index(newer_game)).to be < recent_games.index(older_game)
      end
    end
  end

  describe "callbacks" do
    describe "set_started_at" do
      it "sets started_at on create if not provided" do
        game = build(:game, started_at: nil)
        game.save!
        expect(game.started_at).to be_present
      end

      it "does not override started_at if provided" do
        specific_time = 1.week.ago
        game = create(:game, started_at: specific_time)
        expect(game.started_at).to be_within(1.second).of(specific_time)
      end
    end

    describe "set_starting_location" do
      it "sets current_location to a random location on create if not provided" do
        location1 = create(:location)
        location2 = create(:location)

        game = build(:game, current_location: nil)
        game.save!

        expect(game.current_location).to be_present
        expect([location1, location2]).to include(game.current_location)
      end

      it "does not override current_location if provided" do
        specific_location = create(:location, name: "Specific Location")
        create(:location, name: "Other Location")

        game = create(:game, current_location: specific_location)

        expect(game.current_location).to eq(specific_location)
      end
    end
  end

  describe "#total_cash" do
    it "calculates total cash as cash + bank_balance - debt" do
      game = build(:game, cash: 1000, bank_balance: 500, debt: 200)
      expect(game.total_cash).to eq(1300)
    end

    it "handles games with no debt" do
      game = build(:game, cash: 1000, bank_balance: 500, debt: 0)
      expect(game.total_cash).to eq(1500)
    end

    it "can be negative if debt exceeds liquid cash" do
      game = build(:game, cash: 100, bank_balance: 200, debt: 500)
      expect(game.total_cash).to eq(-200)
    end
  end

  describe "#net_worth" do
    it "returns total_cash" do
      game = build(:game, cash: 1000, bank_balance: 500, debt: 200)
      expect(game.net_worth).to eq(game.total_cash)
    end
  end

  describe "#days_remaining" do
    it "calculates days remaining" do
      game = build(:game, current_day: 5)
      expect(game.days_remaining).to eq(25)
    end

    it "returns 0 on day 30" do
      game = build(:game, current_day: 30)
      expect(game.days_remaining).to eq(0)
    end
  end

  describe "status predicates" do
    describe "#active?" do
      it "returns true for active games" do
        game = build(:game, status: "active")
        expect(game.active?).to be true
      end

      it "returns false for non-active games" do
        game = build(:game, status: "completed")
        expect(game.active?).to be false
      end
    end

    describe "#completed?" do
      it "returns true for completed games" do
        game = build(:game, status: "completed")
        expect(game.completed?).to be true
      end

      it "returns false for non-completed games" do
        game = build(:game, status: "active")
        expect(game.completed?).to be false
      end
    end

    describe "#game_over?" do
      it "returns true for game over games" do
        game = build(:game, status: "game_over")
        expect(game.game_over?).to be true
      end

      it "returns false for non-game-over games" do
        game = build(:game, status: "active")
        expect(game.game_over?).to be false
      end
    end

    describe "#finished?" do
      it "returns true for completed games" do
        game = build(:game, status: "completed")
        expect(game.finished?).to be true
      end

      it "returns true for game over games" do
        game = build(:game, status: "game_over")
        expect(game.finished?).to be true
      end

      it "returns false for active games" do
        game = build(:game, status: "active")
        expect(game.finished?).to be false
      end
    end
  end

  describe "#can_continue?" do
    it "returns true for active game with days remaining and health" do
      game = build(:game, status: "active", current_day: 15, health: 5)
      expect(game.can_continue?).to be true
    end

    it "returns false if game is not active" do
      game = build(:game, status: "completed", current_day: 15, health: 5)
      expect(game.can_continue?).to be false
    end

    it "returns false if current_day exceeds 30" do
      game = build(:game, status: "active", current_day: 31, health: 5)
      expect(game.can_continue?).to be false
    end

    it "returns false if health is 0" do
      game = build(:game, status: "active", current_day: 15, health: 0)
      expect(game.can_continue?).to be false
    end
  end

  describe "#advance_day!" do
    it "increments current_day by 1" do
      game = create(:game, current_day: 5)
      expect { game.advance_day! }.to change { game.current_day }.from(5).to(6)
    end

    it "returns true on success" do
      game = create(:game, current_day: 5)
      expect(game.advance_day!).to be true
    end

    it "completes the game when reaching day 30" do
      game = create(:game, current_day: 29)
      game.advance_day!
      game.reload

      expect(game.current_day).to eq(30)
      expect(game.status).to eq("completed")
      expect(game.completed_at).to be_present
      expect(game.final_score).to be_present
    end

    it "does not advance if game cannot continue" do
      game = create(:game, status: "completed", current_day: 30)
      expect { game.advance_day! }.not_to change { game.current_day }
      expect(game.advance_day!).to be false
    end

    it "does not advance if health is 0" do
      game = create(:game, health: 0)
      expect { game.advance_day! }.not_to change { game.current_day }
      expect(game.advance_day!).to be false
    end
  end

  describe "#complete_game!" do
    it "sets status to completed" do
      game = create(:game)
      game.complete_game!
      expect(game.status).to eq("completed")
    end

    it "sets completed_at timestamp" do
      game = create(:game)
      game.complete_game!
      expect(game.completed_at).to be_present
    end

    it "calculates and sets final_score" do
      game = create(:game, cash: 50_000_000)
      game.complete_game!
      expect(game.final_score).to eq(100)
    end

    it "does not update if already finished" do
      game = create(:game, :completed)
      original_completed_at = game.completed_at

      game.complete_game!

      expect(game.completed_at).to eq(original_completed_at)
    end
  end

  describe "#end_game!" do
    it "sets status to game_over" do
      game = create(:game)
      game.end_game!
      expect(game.status).to eq("game_over")
    end

    it "sets completed_at timestamp" do
      game = create(:game)
      game.end_game!
      expect(game.completed_at).to be_present
    end

    it "calculates and sets final_score" do
      game = create(:game, cash: 10_000_000)
      game.end_game!
      expect(game.final_score).to eq(20)
    end

    it "does not update if already finished" do
      game = create(:game, :game_over)
      original_completed_at = game.completed_at

      game.end_game!

      expect(game.completed_at).to eq(original_completed_at)
    end
  end

  describe "#calculate_final_score" do
    it "calculates score as (net_worth / 1M * 2)" do
      game = build(:game, cash: 25_000_000)
      expect(game.calculate_final_score).to eq(50)
    end

    it "caps score at 100" do
      game = build(:game, cash: 100_000_000)
      expect(game.calculate_final_score).to eq(100)
    end

    it "returns 0 for no money" do
      game = build(:game, cash: 0, bank_balance: 0)
      expect(game.calculate_final_score).to eq(0)
    end

    it "includes bank balance in calculation" do
      game = build(:game, cash: 10_000_000, bank_balance: 15_000_000)
      expect(game.calculate_final_score).to eq(50)
    end

    it "subtracts debt from calculation" do
      game = build(:game, cash: 30_000_000, debt: 5_000_000)
      expect(game.calculate_final_score).to eq(50)
    end
  end

  describe "factory traits" do
    it "creates in_progress game" do
      game = create(:game, :in_progress)
      expect(game.current_day).to eq(15)
      expect(game.total_purchases).to be > 0
    end

    it "creates near_end game" do
      game = create(:game, :near_end)
      expect(game.current_day).to eq(28)
      expect(game.cash).to be > 20000
    end

    it "creates completed game" do
      game = create(:game, :completed)
      expect(game.completed?).to be true
      expect(game.final_score).to be_present
    end

    it "creates game_over game" do
      game = create(:game, :game_over)
      expect(game.game_over?).to be true
      expect(game.health).to eq(0)
    end

    it "creates wealthy game" do
      game = create(:game, :wealthy)
      expect(game.net_worth).to be > 500000
    end

    it "creates in_debt game" do
      game = create(:game, :in_debt)
      expect(game.debt).to be > 0
    end
  end

  describe "inventory management" do
    let(:game) { create(:game, cash: 10000, inventory_capacity: 100) }
    let(:resource) { create(:resource, name: "Gold", inventory_size: 5, base_price_min: 100, base_price_max: 200) }
    let(:location) { create(:location) }

    describe "#current_inventory_size" do
      it "returns 0 for empty inventory" do
        expect(game.current_inventory_size).to eq(0)
      end

      it "calculates total inventory size correctly" do
        create(:inventory_item, game: game, resource: resource, quantity: 5)
        expect(game.current_inventory_size).to eq(25) # 5 items × 5 size each
      end

      it "sums multiple items correctly" do
        resource2 = create(:resource, name: "Silver", inventory_size: 2)
        create(:inventory_item, game: game, resource: resource, quantity: 5) # 5 × 5 = 25
        create(:inventory_item, game: game, resource: resource2, quantity: 10) # 10 × 2 = 20
        expect(game.current_inventory_size).to eq(45)
      end
    end

    describe "#available_inventory_space" do
      it "returns full capacity for empty inventory" do
        expect(game.available_inventory_space).to eq(100)
      end

      it "calculates remaining space correctly" do
        create(:inventory_item, game: game, resource: resource, quantity: 5) # Uses 25 space
        expect(game.available_inventory_space).to eq(75)
      end
    end

    describe "#can_add_to_inventory?" do
      it "returns true when space is available" do
        expect(game.can_add_to_inventory?(resource, 10)).to be true # 10 × 5 = 50 space
      end

      it "returns false when space is insufficient" do
        expect(game.can_add_to_inventory?(resource, 21)).to be false # 21 × 5 = 105 > 100
      end

      it "considers existing inventory" do
        create(:inventory_item, game: game, resource: resource, quantity: 10) # Uses 50 space
        expect(game.can_add_to_inventory?(resource, 11)).to be false # Would need 55 more
        expect(game.can_add_to_inventory?(resource, 10)).to be true # Would need 50 more
      end
    end

    describe "#inventory_value" do
      it "returns 0 for empty inventory" do
        expect(game.inventory_value).to eq(0)
      end

      it "calculates total value correctly" do
        create(:inventory_item, game: game, resource: resource, quantity: 5, purchase_price: 100)
        expect(game.inventory_value).to eq(500)
      end

      it "sums multiple items correctly" do
        resource2 = create(:resource, name: "Silver")
        create(:inventory_item, game: game, resource: resource, quantity: 5, purchase_price: 100) # 500
        create(:inventory_item, game: game, resource: resource2, quantity: 3, purchase_price: 50) # 150
        expect(game.inventory_value).to eq(650)
      end
    end

    describe "#net_worth" do
      it "includes inventory value in net worth calculation" do
        game.update(cash: 1000, bank_balance: 500, debt: 200)
        create(:inventory_item, game: game, resource: resource, quantity: 5, purchase_price: 100)

        expect(game.net_worth).to eq(1800) # 1000 + 500 - 200 + 500
      end
    end

    describe "#buy_resource" do
      it "successfully purchases a resource" do
        result = game.buy_resource(resource, 5, 150.00, location)

        expect(result).to be true
        expect(game.reload.cash).to eq(9250.00) # 10000 - 750
        expect(game.inventory_items.count).to eq(1)
        expect(game.inventory_items.first.quantity).to eq(5)
        expect(game.inventory_items.first.purchase_price).to eq(150.00)
        expect(game.total_purchases).to eq(5)
      end

      it "stacks items with same resource and price" do
        game.buy_resource(resource, 3, 100.00)
        game.buy_resource(resource, 2, 100.00)

        game.reload
        expect(game.inventory_items.count).to eq(1)
        expect(game.inventory_items.first.quantity).to eq(5)
      end

      it "creates separate items for different prices" do
        game.buy_resource(resource, 3, 100.00)
        game.buy_resource(resource, 2, 110.00)

        game.reload
        expect(game.inventory_items.count).to eq(2)
        expect(game.inventory_items.sum(:quantity)).to eq(5)
      end

      it "fails when insufficient cash" do
        game.update(cash: 100)
        result = game.buy_resource(resource, 5, 150.00)

        expect(result).to be false
        expect(game.reload.inventory_items.count).to eq(0)
        expect(game.cash).to eq(100) # Cash unchanged
      end

      it "fails when insufficient inventory space" do
        result = game.buy_resource(resource, 21, 100.00) # 21 × 5 = 105 > 100 capacity

        expect(result).to be false
        expect(game.reload.inventory_items.count).to eq(0)
      end

      it "stores purchase_day and location" do
        game.update(current_day: 15)
        game.buy_resource(resource, 3, 100.00, location)

        item = game.inventory_items.first
        expect(item.purchase_day).to eq(15)
        expect(item.purchase_location_id).to eq(location.id)
      end
    end

    describe "#can_purchase?" do
      it "returns true when conditions are met" do
        expect(game.can_purchase?(resource, 5, 100.00)).to be true
      end

      it "returns false when insufficient cash" do
        game.update(cash: 100)
        expect(game.can_purchase?(resource, 5, 150.00)).to be false
      end

      it "returns false when insufficient inventory space" do
        expect(game.can_purchase?(resource, 21, 100.00)).to be false
      end
    end

    describe "#sell_resource" do
      before do
        game.buy_resource(resource, 10, 100.00)
        game.reload
      end

      it "successfully sells a resource using FIFO" do
        result = game.sell_resource(resource, 5, 150.00)

        expect(result).to be true
        expect(game.reload.cash).to eq(9750.00) # 10000 - 1000 + 750
        expect(game.inventory_items.first.quantity).to eq(5)
        expect(game.total_sales).to eq(5)
      end

      it "sells entire stack when quantity matches" do
        result = game.sell_resource(resource, 10, 150.00)

        expect(result).to be true
        expect(game.reload.inventory_items.count).to eq(0)
      end

      it "uses FIFO ordering when multiple stacks exist" do
        # Clear the inventory from the before block
        game.inventory_items.destroy_all

        # Create two stacks at different times
        travel_to 2.days.ago do
          game.buy_resource(resource, 5, 100.00)
        end
        travel_to 1.day.ago do
          game.buy_resource(resource, 3, 110.00)
        end

        game.reload
        initial_count = game.inventory_items.count

        # Sell 6 units - should sell 5 from first stack, 1 from second
        game.sell_resource(resource, 6, 150.00)

        game.reload
        expect(game.inventory_items.count).to eq(1) # First stack destroyed
        expect(game.inventory_items.first.quantity).to eq(2) # 3 - 1 remaining
        expect(game.inventory_items.first.purchase_price).to eq(110.00) # Second stack
      end

      it "fails when insufficient quantity" do
        result = game.sell_resource(resource, 15, 150.00)

        expect(result).to be false
        expect(game.reload.inventory_items.first.quantity).to eq(10) # Unchanged
      end

      it "fails when resource not in inventory" do
        other_resource = create(:resource, name: "Silver")
        result = game.sell_resource(other_resource, 5, 150.00)

        expect(result).to be false
      end
    end

    describe "#can_sell?" do
      it "returns true when resource is in inventory with sufficient quantity" do
        game.buy_resource(resource, 10, 100.00)
        expect(game.can_sell?(resource, 5)).to be true
      end

      it "returns false when insufficient quantity" do
        game.buy_resource(resource, 5, 100.00)
        expect(game.can_sell?(resource, 10)).to be false
      end

      it "returns false when resource not in inventory" do
        other_resource = create(:resource, name: "Silver")
        expect(game.can_sell?(other_resource, 1)).to be false
      end

      it "sums quantities across multiple stacks" do
        game.buy_resource(resource, 3, 100.00)
        game.buy_resource(resource, 2, 110.00)

        expect(game.can_sell?(resource, 5)).to be true
        expect(game.can_sell?(resource, 6)).to be false
      end
    end
  end
end
