require 'rails_helper'

RSpec.describe "Marketplaces", type: :request do
  let(:game) { create(:game, cash: 1000.0) }
  let(:location) { game.current_location }
  let(:resource) { create(:resource) }
  let!(:location_resource) { create(:location_resource, location: location, resource: resource, current_price: 50.0) }

  before do
    # Set up session with game
    allow_any_instance_of(MarketplaceController).to receive(:current_game).and_return(game)
  end

  describe "GET /marketplace" do
    it "returns http success" do
      get "/marketplace"
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /marketplace/sell" do
    before do
      # Give the game some inventory to sell
      game.buy_resource(resource, 10, 25.0)
      game.reload
    end

    context "with valid params" do
      it "redirects to marketplace" do
        post "/marketplace/sell", params: {
          resource_id: resource.id,
          quantity: 5,
          price_per_unit: 50.0
        }

        expect(response).to redirect_to(marketplace_path)
      end

      it "sells the resource" do
        expect {
          post "/marketplace/sell", params: {
            resource_id: resource.id,
            quantity: 5,
            price_per_unit: 50.0
          }
        }.to change { game.inventory_items.where(resource: resource).sum(:quantity) }.from(10).to(5)
      end

      it "updates game cash" do
        expect {
          post "/marketplace/sell", params: {
            resource_id: resource.id,
            quantity: 5,
            price_per_unit: 50.0
          }
          game.reload
        }.to change { game.cash }.by(250.0)
      end

      it "shows success notice" do
        post "/marketplace/sell", params: {
          resource_id: resource.id,
          quantity: 5,
          price_per_unit: 50.0
        }

        expect(flash[:notice]).to match(/Successfully sold 5/)
      end
    end

    context "with invalid params" do
      it "redirects to marketplace with error" do
        post "/marketplace/sell", params: {
          resource_id: resource.id,
          quantity: 100, # More than owned
          price_per_unit: 50.0
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to be_present
      end

      it "does not sell the resource" do
        expect {
          post "/marketplace/sell", params: {
            resource_id: resource.id,
            quantity: 100,
            price_per_unit: 50.0
          }
        }.not_to change { game.inventory_items.where(resource: resource).sum(:quantity) }
      end
    end
  end
end
