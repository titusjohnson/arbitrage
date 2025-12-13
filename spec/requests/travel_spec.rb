require 'rails_helper'

RSpec.describe "Travel", type: :request do
  let!(:location1) { create(:location, name: "New York", x: 0, y: 0) }
  let!(:location2) { create(:location, name: "Boston", x: 1, y: 0) }
  let!(:location3) { create(:location, name: "Philadelphia", x: 0, y: 1) }
  let!(:location4) { create(:location, name: "Chicago", x: 2, y: 2) }
  let(:game) { create(:game, cash: 1000, current_day: 5, current_location: location1) }

  before do
    # Simulate the game session
    allow_any_instance_of(TravelController).to receive(:current_game).and_return(game)
  end

  describe "GET /travel" do
    it "displays the travel page" do
      get travel_path
      expect(response).to have_http_status(:success)
    end

    it "shows all locations" do
      get travel_path
      expect(response.body).to include("New York")
      expect(response.body).to include("Boston")
      expect(response.body).to include("Philadelphia")
      expect(response.body).to include("Chicago")
    end
  end

  describe "POST /travel" do
    context "with valid travel to adjacent location" do
      it "travels to the destination" do
        expect {
          post travel_path, params: { location_id: location2.id }
        }.to change { game.reload.current_location_id }.from(location1.id).to(location2.id)
      end

      it "does not deduct travel cost for adjacent location (free)" do
        expect {
          post travel_path, params: { location_id: location2.id }
        }.not_to change { game.reload.cash }
      end

      it "advances the day" do
        expect {
          post travel_path, params: { location_id: location2.id }
        }.to change { game.reload.current_day }.by(1)
      end

      it "increments locations_visited" do
        expect {
          post travel_path, params: { location_id: location2.id }
        }.to change { game.reload.locations_visited }.by(1)
      end

      it "redirects to root with success message" do
        post travel_path, params: { location_id: location2.id }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Traveled to Boston")
      end
    end

    context "with long-distance travel" do
      it "travels to the distant location" do
        expect {
          post travel_path, params: { location_id: location4.id }
        }.to change { game.reload.current_location_id }.from(location1.id).to(location4.id)
      end

      it "deducts correct travel cost based on distance" do
        # Distance from (0,0) to (2,2) is 4, cost is (4-1)*100 = $300
        expect {
          post travel_path, params: { location_id: location4.id }
        }.to change { game.reload.cash }.by(-300)
      end

      it "redirects to root with success message" do
        post travel_path, params: { location_id: location4.id }
        expect(response).to redirect_to(root_path)
        follow_redirect!
        expect(response.body).to include("Traveled to Chicago")
      end
    end

    context "with insufficient cash" do
      before do
        game.update!(cash: 50)
      end

      it "does not change location" do
        expect {
          post travel_path, params: { location_id: location4.id } # Far location requires cash
        }.not_to change { game.reload.current_location_id }
      end

      it "redirects to travel with error message" do
        post travel_path, params: { location_id: location4.id } # Far location requires cash
        expect(response).to redirect_to(travel_path)
        follow_redirect!
        expect(response.body).to include("Not enough cash for this journey")
      end
    end

    context "with same location as current" do
      it "does not allow travel" do
        expect {
          post travel_path, params: { location_id: location1.id }
        }.not_to change { game.reload.current_day }
      end

      it "redirects to travel with error message" do
        post travel_path, params: { location_id: location1.id }
        expect(response).to redirect_to(travel_path)
        follow_redirect!
        expect(response.body).to include("must be different from current location")
      end
    end

    context "with non-existent location" do
      it "does not allow travel" do
        expect {
          post travel_path, params: { location_id: 99999 }
        }.not_to change { game.reload.current_day }
      end

      it "redirects to travel with error message" do
        post travel_path, params: { location_id: 99999 }
        expect(response).to redirect_to(travel_path)
        follow_redirect!
        expect(response.body).to include("does not exist")
      end
    end
  end
end
