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

  describe "POST /marketplace/buy" do
    context "with valid params and sufficient cash" do
      it "redirects to marketplace" do
        post "/marketplace/buy", params: {
          location_resource_id: location_resource.id,
          quantity: 5
        }

        expect(response).to redirect_to(marketplace_path)
      end

      it "purchases the resource" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: location_resource.id,
            quantity: 5
          }
        }.to change { game.inventory_items.where(resource: resource).sum(:quantity) }.from(0).to(5)
      end

      it "deducts cash from game" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: location_resource.id,
            quantity: 5
          }
          game.reload
        }.to change { game.cash }.by(-250.0)
      end

      it "decrements available quantity at location" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: location_resource.id,
            quantity: 5
          }
          location_resource.reload
        }.to change { location_resource.available_quantity }.by(-5)
      end

      it "shows success notice" do
        post "/marketplace/buy", params: {
          location_resource_id: location_resource.id,
          quantity: 5
        }

        expect(flash[:notice]).to match(/Successfully purchased 5/)
      end
    end

    context "with insufficient cash" do
      before do
        game.update!(cash: 100.0)
      end

      it "redirects to marketplace with error" do
        post "/marketplace/buy", params: {
          location_resource_id: location_resource.id,
          quantity: 10 # 10 * 50 = 500, but only have 100
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to include("insufficient funds")
      end

      it "does not purchase the resource" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: location_resource.id,
            quantity: 10
          }
        }.not_to change { game.inventory_items.where(resource: resource).sum(:quantity) }
      end

      it "does not deduct cash" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: location_resource.id,
            quantity: 10
          }
          game.reload
        }.not_to change { game.cash }
      end
    end

    context "with insufficient inventory capacity" do
      let(:bulky_resource) { create(:resource, inventory_size: 30) }
      let!(:bulky_location_resource) { create(:location_resource, location: location, resource: bulky_resource, current_price: 10.0) }

      before do
        game.update!(inventory_capacity: 100, cash: 10000)
      end

      it "redirects to marketplace with error" do
        post "/marketplace/buy", params: {
          location_resource_id: bulky_location_resource.id,
          quantity: 5 # 5 * 30 = 150 space needed, but only have 100
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to include("insufficient space")
      end

      it "does not purchase the resource" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: bulky_location_resource.id,
            quantity: 5
          }
        }.not_to change { game.inventory_items.where(resource: bulky_resource).sum(:quantity) }
      end
    end

    context "with insufficient available quantity at location" do
      before do
        location_resource.update!(available_quantity: 3)
      end

      it "redirects to marketplace with error" do
        post "/marketplace/buy", params: {
          location_resource_id: location_resource.id,
          quantity: 5 # Want 5, but only 3 available
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to include("insufficient stock")
      end

      it "does not purchase the resource" do
        expect {
          post "/marketplace/buy", params: {
            location_resource_id: location_resource.id,
            quantity: 5
          }
        }.not_to change { game.inventory_items.where(resource: resource).sum(:quantity) }
      end
    end

    context "with invalid location_resource_id" do
      it "redirects to marketplace with error" do
        post "/marketplace/buy", params: {
          location_resource_id: 99999, # Non-existent
          quantity: 5
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to be_present
      end
    end

    context "with invalid quantity" do
      it "redirects to marketplace with error for zero quantity" do
        post "/marketplace/buy", params: {
          location_resource_id: location_resource.id,
          quantity: 0
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to be_present
      end

      it "redirects to marketplace with error for negative quantity" do
        post "/marketplace/buy", params: {
          location_resource_id: location_resource.id,
          quantity: -5
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to be_present
      end
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
          location_resource_id: location_resource.id,
          quantity: 5
        }

        expect(response).to redirect_to(marketplace_path)
      end

      it "sells the resource" do
        expect {
          post "/marketplace/sell", params: {
            location_resource_id: location_resource.id,
            quantity: 5
          }
        }.to change { game.inventory_items.where(resource: resource).sum(:quantity) }.from(10).to(5)
      end

      it "updates game cash" do
        expect {
          post "/marketplace/sell", params: {
            location_resource_id: location_resource.id,
            quantity: 5
          }
          game.reload
        }.to change { game.cash }.by(250.0)
      end

      it "shows success notice" do
        post "/marketplace/sell", params: {
          location_resource_id: location_resource.id,
          quantity: 5
        }

        expect(flash[:notice]).to match(/Successfully sold 5/)
      end
    end

    context "with invalid params" do
      it "redirects to marketplace with error" do
        post "/marketplace/sell", params: {
          location_resource_id: location_resource.id,
          quantity: 100 # More than owned
        }

        expect(response).to redirect_to(marketplace_path)
        expect(flash[:alert]).to be_present
      end

      it "does not sell the resource" do
        expect {
          post "/marketplace/sell", params: {
            location_resource_id: location_resource.id,
            quantity: 100
          }
        }.not_to change { game.inventory_items.where(resource: resource).sum(:quantity) }
      end
    end
  end
end
