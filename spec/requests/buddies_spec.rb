require 'rails_helper'

RSpec.describe "Buddies", type: :request do
  let(:location) { create(:location) }
  let(:game) { create(:game, current_location: location, cash: 5000) }

  before do
    sign_in_with_game(game)
  end

  describe "GET /buddies" do
    it "returns http success" do
      get "/buddies"
      expect(response).to have_http_status(:success)
    end

    it "displays buddies at current location" do
      buddy = game.buddies.create!(
        name: "Vinnie",
        location: location,
        hire_cost: 100,
        hire_day: 1
      )

      get "/buddies"

      expect(response.body).to include("Vinnie")
    end

    it "displays buddies at other locations" do
      other_location = create(:location, name: "Other City")
      buddy = game.buddies.create!(
        name: "Marco",
        location: other_location,
        hire_cost: 100,
        hire_day: 1
      )

      get "/buddies"

      expect(response.body).to include("Marco")
    end
  end

  describe "GET /buddies/:id" do
    it "returns http success" do
      buddy = game.buddies.create!(
        name: "Tony",
        location: location,
        hire_cost: 100,
        hire_day: 1
      )

      get "/buddies/#{buddy.id}"

      expect(response).to have_http_status(:success)
    end

    it "displays buddy details" do
      buddy = game.buddies.create!(
        name: "Sal",
        location: location,
        hire_cost: 100,
        hire_day: 1
      )

      get "/buddies/#{buddy.id}"

      expect(response.body).to include("Sal")
    end
  end

  describe "POST /buddies" do
    it "hires a buddy successfully" do
      expect {
        post "/buddies"
      }.to change { game.buddies.count }.by(1)

      expect(response).to redirect_to(buddies_path)
    end

    it "deducts hire cost from cash" do
      post "/buddies"

      game.reload
      expect(game.cash).to eq(4900) # 5000 - 100
    end

    it "fails when insufficient cash" do
      game.update!(cash: 50)

      expect {
        post "/buddies"
      }.not_to change { game.buddies.count }

      expect(response).to redirect_to(buddies_path)
      expect(flash[:alert]).to be_present
    end

    context "with turbo_stream format" do
      it "returns turbo_stream response on success" do
        post "/buddies", headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end

      it "returns turbo_stream response on failure" do
        game.update!(cash: 50)

        post "/buddies", headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "POST /buddies/:id/assign" do
    let(:resource) { create(:resource, name: "Gold Bar") }
    let(:buddy) do
      game.buddies.create!(
        name: "Louie",
        location: location,
        hire_cost: 100,
        hire_day: 1,
        status: 'idle'
      )
    end

    before do
      create(:inventory_item, game: game, resource: resource, quantity: 10, purchase_price: 100.0)
    end

    it "assigns resource to buddy successfully" do
      post "/buddies/#{buddy.id}/assign", params: {
        buddy: { resource_id: resource.id, quantity: 5, target_profit_percent: 25 }
      }

      buddy.reload
      expect(buddy.resource).to eq(resource)
      expect(buddy.quantity).to eq(5)
      expect(buddy.status).to eq('holding')
    end

    it "removes resource from inventory" do
      expect {
        post "/buddies/#{buddy.id}/assign", params: {
          buddy: { resource_id: resource.id, quantity: 5, target_profit_percent: 25 }
        }
      }.to change { game.inventory_items.sum(:quantity) }.by(-5)
    end

    it "fails when buddy is not idle" do
      buddy.update!(status: 'holding', resource: resource, quantity: 1, purchase_price: 100)

      post "/buddies/#{buddy.id}/assign", params: {
        buddy: { resource_id: resource.id, quantity: 5, target_profit_percent: 25 }
      }

      expect(response).to redirect_to(buddy_path(buddy))
      expect(flash[:alert]).to be_present
    end

    it "fails when buddy is at different location" do
      other_location = create(:location)
      buddy.update!(location: other_location)

      post "/buddies/#{buddy.id}/assign", params: {
        buddy: { resource_id: resource.id, quantity: 5, target_profit_percent: 25 }
      }

      expect(response).to redirect_to(buddy_path(buddy))
      expect(flash[:alert]).to be_present
    end

    it "fails with insufficient inventory" do
      post "/buddies/#{buddy.id}/assign", params: {
        buddy: { resource_id: resource.id, quantity: 100, target_profit_percent: 25 }
      }

      expect(response).to redirect_to(buddy_path(buddy))
      expect(flash[:alert]).to be_present
    end

    context "with turbo_stream format" do
      it "returns turbo_stream response on success" do
        post "/buddies/#{buddy.id}/assign",
             params: { buddy: { resource_id: resource.id, quantity: 5, target_profit_percent: 25 } },
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end

  describe "POST /buddies/:id/collect" do
    let(:resource) { create(:resource, name: "Silver Bar") }
    let(:buddy) do
      game.buddies.create!(
        name: "Frankie",
        location: location,
        hire_cost: 100,
        hire_day: 1,
        status: 'sold',
        resource: resource,
        quantity: 5,
        purchase_price: 100.0,
        last_sale_profit: 50.0
      )
    end

    it "collects sale proceeds successfully" do
      initial_cash = game.cash

      post "/buddies/#{buddy.id}/collect"

      game.reload
      expect(game.cash).to be > initial_cash
    end

    it "resets buddy to idle status" do
      post "/buddies/#{buddy.id}/collect"

      buddy.reload
      expect(buddy.status).to eq('idle')
      expect(buddy.resource).to be_nil
      expect(buddy.quantity).to eq(0)
    end

    it "fails when buddy has no sale" do
      buddy.update!(status: 'idle', resource: nil, quantity: 0, purchase_price: nil, last_sale_profit: nil)

      post "/buddies/#{buddy.id}/collect"

      expect(response).to redirect_to(buddies_path)
      expect(flash[:alert]).to be_present
    end

    it "fails when buddy is at different location" do
      other_location = create(:location)
      buddy.update!(location: other_location)

      post "/buddies/#{buddy.id}/collect"

      expect(response).to redirect_to(buddies_path)
      expect(flash[:alert]).to be_present
    end

    context "with turbo_stream format" do
      it "returns turbo_stream response on success" do
        post "/buddies/#{buddy.id}/collect",
             headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response.media_type).to eq("text/vnd.turbo-stream.html")
      end
    end
  end
end
