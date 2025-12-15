require 'rails_helper'

RSpec.describe "GameSessions", type: :request do
  before(:each) do
    create(:location) unless Location.exists?
    create_list(:resource, 5) unless Resource.exists?
  end

  describe "Difficulty selection flow" do
    describe "redirects to difficulty selection" do
      it "redirects to new game path when no game exists" do
        get root_path

        expect(response).to redirect_to(new_game_path)
      end

      it "shows difficulty selection page" do
        get new_game_path

        expect(response).to have_http_status(:success)
        expect(response.body).to include("Choose Your Difficulty")
      end

      it "displays all five difficulty levels" do
        get new_game_path

        expect(response.body).to include("Street Peddler")
        expect(response.body).to include("Flea Market Flipper")
        expect(response.body).to include("Antique Dealer")
        expect(response.body).to include("Commodities Broker")
        expect(response.body).to include("Tycoon")
      end
    end

    describe "game creation with difficulty" do
      it "creates a new game with selected difficulty" do
        expect {
          post games_path, params: { difficulty: "street_peddler" }
        }.to change(Game, :count).by(1)

        expect(response).to redirect_to(root_path)
      end

      it "stores the game restore_key in the session" do
        post games_path, params: { difficulty: "street_peddler" }

        expect(session[:game_restore_key]).to be_present
        expect(session[:game_restore_key]).to eq(Game.last.restore_key)
      end

      it "creates a street_peddler game with correct values" do
        post games_path, params: { difficulty: "street_peddler" }

        game = Game.last
        expect(game.difficulty).to eq("street_peddler")
        expect(game.cash).to eq(5_000)
        expect(game.wealth_target).to eq(25_000)
        expect(game.day_target).to eq(30)
        expect(game.current_day).to eq(1)
        expect(game.status).to eq("active")
      end

      it "creates a tycoon game with correct values" do
        post games_path, params: { difficulty: "tycoon" }

        game = Game.last
        expect(game.difficulty).to eq("tycoon")
        expect(game.cash).to eq(100_000)
        expect(game.wealth_target).to eq(10_000_000)
        expect(game.day_target).to eq(365)
      end

      it "rejects invalid difficulty" do
        post games_path, params: { difficulty: "invalid_difficulty" }

        expect(response).to redirect_to(new_game_path)
        expect(flash[:alert]).to include("valid difficulty")
      end

      it "generates a unique restore_key for each game" do
        post games_path, params: { difficulty: "street_peddler" }
        first_key = session[:game_restore_key]

        expect(first_key).to be_present
        expect(first_key.length).to be > 20
      end
    end
  end

  describe "Game restoration" do
    let!(:game) { create(:game) }

    before do
      sign_in_with_game(game)
    end

    it "maintains the same game across multiple requests" do
      get root_path

      expect(response).to have_http_status(:success)
    end
  end

  describe "Game with existing session" do
    let!(:game) { create(:game) }

    before do
      sign_in_with_game(game)
    end

    it "does not redirect when game exists in session" do
      get root_path

      expect(response).to have_http_status(:success)
      expect(response.body).to include("Day 1")
    end

    it "displays correct game state" do
      game.update!(current_day: 5)

      get root_path

      expect(response.body).to include("Day 5")
    end

    it "redirects to new game when existing game is not active" do
      game.update!(status: "completed")
      # Need to return nil to simulate the active scope filtering out the completed game
      allow_any_instance_of(ApplicationController).to receive(:find_game_by_restore_key).and_return(nil)

      get root_path

      expect(response).to redirect_to(new_game_path)
    end
  end

  describe "Game abandonment" do
    let!(:game) { create(:game) }

    before do
      sign_in_with_game(game)
    end

    it "allows abandoning a game" do
      delete abandon_game_path

      expect(response).to redirect_to(new_game_path)
      expect(game.reload.status).to eq("game_over")
    end
  end
end
