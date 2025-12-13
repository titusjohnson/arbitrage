require 'rails_helper'

RSpec.describe "GameSessions", type: :request do
  # Ensure at least one location exists for game creation
  before(:each) do
    create(:location) unless Location.exists?
  end

  describe "Anonymous game creation and restoration" do
    describe "automatic game creation" do
      it "creates a new game on first visit" do
        expect {
          get root_path
        }.to change(Game, :count).by(1)

        expect(response).to have_http_status(:success)
      end

      it "stores the game restore_key in the session" do
        get root_path

        expect(session[:game_restore_key]).to be_present
        expect(session[:game_restore_key]).to eq(Game.last.restore_key)
      end

      it "creates a game with default starting values" do
        get root_path

        game = Game.last
        expect(game.current_day).to eq(1)
        expect(game.cash).to eq(5000.00)
        expect(game.bank_balance).to eq(0.00)
        expect(game.debt).to eq(0.00)
        expect(game.status).to eq("active")
        expect(game.health).to eq(10)
        expect(game.max_health).to eq(10)
        expect(game.inventory_capacity).to eq(100)
      end

      it "generates a unique restore_key for each game" do
        get root_path
        first_key = session[:game_restore_key]

        expect(first_key).to be_present
        expect(first_key.length).to be > 20
      end
    end

    describe "game restoration" do
      it "maintains the same game across multiple requests in the same session" do
        get root_path
        first_request_key = session[:game_restore_key]
        first_game_id = Game.last.id

        get root_path
        second_request_key = session[:game_restore_key]

        expect(second_request_key).to eq(first_request_key)
        expect(Game.count).to eq(1)
        expect(Game.last.id).to eq(first_game_id)
      end

      it "restores game state from the database on each request" do
        get root_path
        game = Game.last

        game.update!(current_day: 15, cash: 5000)

        get root_path

        restored_game = Game.find_by(restore_key: session[:game_restore_key])
        expect(restored_game.current_day).to eq(15)
        expect(restored_game.cash).to eq(5000)
      end

      it "persists game progress across multiple page loads" do
        get root_path
        game = Game.last
        initial_day = game.current_day

        game.advance_day!
        game.advance_day!

        get root_path

        reloaded_game = Game.find_by(restore_key: session[:game_restore_key])
        expect(reloaded_game.current_day).to eq(initial_day + 2)
      end
    end

    describe "handling invalid or missing restore keys" do
      it "creates new game when restore_key is invalid" do
        get root_path
        original_key = session[:game_restore_key]
        original_game = Game.last

        expect(original_game).to be_present
        expect(original_game.restore_key).to eq(original_key)
      end

      it "always ensures a game exists for the session" do
        get root_path
        expect(Game.count).to eq(1)
        expect(session[:game_restore_key]).to be_present

        get root_path
        expect(Game.count).to eq(1)
      end

      it "generates valid restore_key on game creation" do
        get root_path
        game = Game.last

        expect(game.restore_key).to be_present
        expect(game.restore_key).to match(/\A[\w\-]+\z/)
        expect(game.restore_key.length).to be >= 32
      end
    end

    describe "session isolation" do
      it "each test example gets a new game" do
        get root_path

        expect(session[:game_restore_key]).to be_present
        expect(Game.count).to eq(1)
      end

      it "different test examples create different games" do
        get root_path
        this_test_key = session[:game_restore_key]

        expect(Game.find_by(restore_key: this_test_key)).to be_present
      end
    end

    describe "game state persistence" do
      it "maintains game state across multiple page loads" do
        get root_path
        game = Game.last

        game.update!(current_day: 5, cash: 3500, health: 7)

        get root_path

        restored_game = Game.find_by(restore_key: session[:game_restore_key])
        expect(restored_game.id).to eq(game.id)
        expect(restored_game.current_day).to eq(5)
        expect(restored_game.cash).to eq(3500)
        expect(restored_game.health).to eq(7)
      end

      it "reflects database changes on next request" do
        get root_path
        game = Game.last

        game.update!(current_day: 10, health: 5, cash: 8000)

        get root_path

        reloaded_game = Game.find_by(restore_key: session[:game_restore_key])
        expect(reloaded_game.current_day).to eq(10)
        expect(reloaded_game.health).to eq(5)
        expect(reloaded_game.cash).to eq(8000)
      end

      it "maintains financial state across requests" do
        get root_path
        game = Game.last

        game.update!(
          cash: 15000,
          bank_balance: 25000,
          debt: 5000
        )

        get root_path

        reloaded_game = Game.find_by(restore_key: session[:game_restore_key])
        expect(reloaded_game.cash).to eq(15000)
        expect(reloaded_game.bank_balance).to eq(25000)
        expect(reloaded_game.debt).to eq(5000)
        expect(reloaded_game.total_cash).to eq(35000)
      end
    end

    describe "current_game helper" do
      it "displays Day 1 on first visit" do
        get root_path

        expect(response.body).to include("Day 1")
      end

      it "displays the correct current day after progression" do
        get root_path
        game = Game.last

        game.update!(current_day: 5)

        get root_path

        expect(response.body).to include("Day 5")
      end

      it "updates display when game advances" do
        get root_path
        game = Game.last

        game.advance_day!
        game.advance_day!
        game.advance_day!

        get root_path

        expect(response.body).to include("Day 4")
      end

      it "displays correct day for mid-game state" do
        get root_path
        game = Game.last

        game.update!(current_day: 20)

        get root_path

        expect(response.body).to include("Day 20")
      end
    end

    describe "game lifecycle" do
      it "continues using the same game until it's finished" do
        get root_path
        game = Game.last
        game_id = game.id

        5.times do
          get root_path
          expect(Game.last.id).to eq(game_id)
        end

        expect(Game.count).to eq(1)
      end

      it "preserves game statistics across requests" do
        get root_path
        game = Game.last

        game.update!(
          total_purchases: 25,
          total_sales: 18,
          locations_visited: 7,
          best_deal_profit: 1500
        )

        get root_path

        reloaded_game = Game.find_by(restore_key: session[:game_restore_key])
        expect(reloaded_game.total_purchases).to eq(25)
        expect(reloaded_game.total_sales).to eq(18)
        expect(reloaded_game.locations_visited).to eq(7)
        expect(reloaded_game.best_deal_profit).to eq(1500)
      end
    end
  end
end
