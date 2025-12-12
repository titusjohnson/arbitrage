require 'rails_helper'

# == Schema Information
#
# Table name: inventory_items
#
#  id                   :integer          not null, primary key
#  game_id              :integer          not null
#  resource_id          :integer          not null
#  quantity             :integer          default(1), not null
#  purchase_price       :decimal(10, 2)   not null
#  purchase_day         :integer          not null
#  purchase_location_id :integer
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#
# Indexes
#
#  index_inventory_items_on_game_id                  (game_id)
#  index_inventory_items_on_game_id_and_resource_id  (game_id,resource_id)
#  index_inventory_items_on_resource_id              (resource_id)
#
# Foreign Keys
#
#  game_id      (game_id => games.id)
#  resource_id  (resource_id => resources.id)
#
RSpec.describe InventoryItem, type: :model do
  describe "associations" do
    it "belongs to game" do
      inventory_item = create(:inventory_item)
      expect(inventory_item.game).to be_a(Game)
    end

    it "belongs to resource" do
      inventory_item = create(:inventory_item)
      expect(inventory_item.resource).to be_a(Resource)
    end

    it "belongs to purchase_location optionally" do
      inventory_item = create(:inventory_item, :with_location)
      expect(inventory_item.purchase_location).to be_a(Location)
    end

    it "is valid without a purchase_location" do
      inventory_item = build(:inventory_item, purchase_location_id: nil)
      expect(inventory_item).to be_valid
    end

    it "is invalid without a game" do
      inventory_item = build(:inventory_item, game: nil)
      expect(inventory_item).not_to be_valid
    end

    it "is invalid without a resource" do
      inventory_item = build(:inventory_item, resource: nil)
      expect(inventory_item).not_to be_valid
    end
  end

  describe "validations" do
    it "validates presence of quantity" do
      inventory_item = build(:inventory_item, quantity: nil)
      expect(inventory_item).not_to be_valid
      expect(inventory_item.errors[:quantity]).to include("can't be blank")
    end

    it "validates quantity is greater than 0" do
      inventory_item = build(:inventory_item, quantity: 0)
      expect(inventory_item).not_to be_valid
      expect(inventory_item.errors[:quantity]).to include("must be greater than 0")
    end

    it "validates quantity is an integer" do
      inventory_item = build(:inventory_item, quantity: 1.5)
      expect(inventory_item).not_to be_valid
    end

    it "validates presence of purchase_price" do
      inventory_item = build(:inventory_item, purchase_price: nil)
      expect(inventory_item).not_to be_valid
      expect(inventory_item.errors[:purchase_price]).to include("can't be blank")
    end

    it "validates purchase_price is greater than 0" do
      inventory_item = build(:inventory_item, purchase_price: 0)
      expect(inventory_item).not_to be_valid
      expect(inventory_item.errors[:purchase_price]).to include("must be greater than 0")
    end

    it "validates presence of purchase_day" do
      inventory_item = build(:inventory_item, purchase_day: nil)
      expect(inventory_item).not_to be_valid
      expect(inventory_item.errors[:purchase_day]).to include("can't be blank")
    end

    it "validates purchase_day is between 1 and 30" do
      expect(build(:inventory_item, purchase_day: 0)).not_to be_valid
      expect(build(:inventory_item, purchase_day: 31)).not_to be_valid
      expect(build(:inventory_item, purchase_day: 1)).to be_valid
      expect(build(:inventory_item, purchase_day: 30)).to be_valid
    end
  end

  describe "scopes" do
    let!(:game) { create(:game) }
    let!(:resource1) { create(:resource, name: "Gold") }
    let!(:resource2) { create(:resource, name: "Silver") }

    before do
      # Create items with different created_at times
      travel_to 3.days.ago do
        create(:inventory_item, game: game, resource: resource1, quantity: 5)
      end
      travel_to 2.days.ago do
        create(:inventory_item, game: game, resource: resource2, quantity: 3)
      end
      travel_to 1.day.ago do
        create(:inventory_item, game: game, resource: resource1, quantity: 2)
      end
    end

    describe ".fifo" do
      it "returns items ordered by created_at ascending (oldest first)" do
        items = game.inventory_items.fifo
        expect(items.first.quantity).to eq(5)
        expect(items.second.quantity).to eq(3)
        expect(items.third.quantity).to eq(2)
      end
    end

    describe ".by_resource" do
      it "returns items for a specific resource" do
        items = game.inventory_items.by_resource(resource1)
        expect(items.count).to eq(2)
        expect(items.sum(:quantity)).to eq(7)
      end
    end
  end

  describe "#total_value" do
    it "calculates the total value of the inventory item" do
      inventory_item = create(:inventory_item, quantity: 5, purchase_price: 100.50)
      expect(inventory_item.total_value).to eq(502.5)
    end

    it "works with decimal prices" do
      inventory_item = create(:inventory_item, quantity: 3, purchase_price: 99.99)
      expect(inventory_item.total_value).to eq(299.97)
    end
  end

  describe "integration with Game and Resource" do
    it "creates a valid inventory_item with associations" do
      game = create(:game)
      resource = create(:resource)
      inventory_item = create(:inventory_item, game: game, resource: resource)

      expect(inventory_item.game).to eq(game)
      expect(inventory_item.resource).to eq(resource)
      expect(game.inventory_items).to include(inventory_item)
      expect(resource.inventory_items).to include(inventory_item)
    end

    it "allows multiple inventory items per game" do
      game = create(:game)
      resource1 = create(:resource, name: "Gold")
      resource2 = create(:resource, name: "Silver")

      item1 = create(:inventory_item, game: game, resource: resource1)
      item2 = create(:inventory_item, game: game, resource: resource2)

      expect(game.inventory_items.count).to eq(2)
      expect(game.resources).to match_array([resource1, resource2])
    end

    it "destroys inventory items when game is destroyed" do
      game = create(:game)
      item = create(:inventory_item, game: game)

      expect { game.destroy }.to change { InventoryItem.count }.by(-1)
    end

    it "destroys inventory items when resource is destroyed" do
      resource = create(:resource)
      item = create(:inventory_item, resource: resource)

      expect { resource.destroy }.to change { InventoryItem.count }.by(-1)
    end
  end
end
