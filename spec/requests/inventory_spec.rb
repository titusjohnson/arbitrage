require 'rails_helper'

RSpec.describe "Inventories", type: :request do
  let(:game) { create(:game) }

  before do
    sign_in_with_game(game)
  end

  describe "GET /inventory" do
    it "returns http success" do
      get "/inventory"
      expect(response).to have_http_status(:success)
    end

    it "displays inventory items when they exist" do
      resource = create(:resource, name: "Gold Bar")
      create(:inventory_item, game: game, resource: resource, quantity: 5, purchase_price: 100.0)

      get "/inventory"

      expect(response.body).to include("Gold Bar")
      expect(response.body).to include("5 units")
    end

    it "displays empty state when inventory is empty" do
      get "/inventory"

      expect(response.body).to include("Your inventory is empty")
    end

    it "displays inventory statistics" do
      resource = create(:resource, inventory_size: 2)
      create(:inventory_item, game: game, resource: resource, quantity: 10, purchase_price: 50.0)

      get "/inventory"

      expect(response.body).to include("Capacity:")
      expect(response.body).to include("Total Value:")
      expect(response.body).to include("Items:")
    end
  end
end
