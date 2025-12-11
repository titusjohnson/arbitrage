require 'rails_helper'

# == Schema Information
#
# Table name: resources
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  description      :text
#  base_price_min   :decimal(10, 2)   not null
#  base_price_max   :decimal(10, 2)   not null
#  price_volatility :decimal(5, 2)    default(50.0), not null
#  inventory_size   :integer          default(1), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
# Indexes
#
#  index_resources_on_name  (name) UNIQUE
#
RSpec.describe Resource, type: :model do
  describe "scopes" do
    let!(:low_vol_resource) { create(:resource, name: "Stable Goods", price_volatility: 20.00) }
    let!(:mid_vol_resource) { create(:resource, name: "Normal Goods", price_volatility: 50.00) }
    let!(:high_vol_resource) { create(:resource, name: "Volatile Goods", price_volatility: 85.00) }

    describe ".ordered_by_name" do
      it "returns resources in alphabetical order" do
        expect(Resource.ordered_by_name.pluck(:name)).to eq(["Normal Goods", "Stable Goods", "Volatile Goods"])
      end
    end

    describe ".high_volatility" do
      it "returns resources with volatility >= 75" do
        expect(Resource.high_volatility).to eq([high_vol_resource])
      end
    end

    describe ".low_volatility" do
      it "returns resources with volatility <= 25" do
        expect(Resource.low_volatility).to eq([low_vol_resource])
      end
    end
  end

  describe "#price_range" do
    it "returns a range from min to max price" do
      resource = build(:resource, base_price_min: 100, base_price_max: 500)
      expect(resource.price_range).to eq(100..500)
    end
  end

  describe "#average_price" do
    it "calculates the midpoint between min and max" do
      resource = build(:resource, base_price_min: 100, base_price_max: 500)
      expect(resource.average_price).to eq(300)
    end

    it "handles decimal values" do
      resource = build(:resource, base_price_min: 100.50, base_price_max: 200.50)
      expect(resource.average_price).to eq(150.50)
    end
  end

  describe "#generate_market_price" do
    let(:resource) { build(:resource, base_price_min: 100, base_price_max: 500, price_volatility: 50) }

    it "returns a positive price" do
      price = resource.generate_market_price
      expect(price).to be > 0
    end

    it "returns a decimal value with 2 decimal places" do
      price = resource.generate_market_price
      expect(price).to eq(price.round(2))
    end

    it "generates varied prices on multiple calls" do
      prices = 10.times.map { resource.generate_market_price }
      expect(prices.uniq.length).to be > 1
    end

    it "never returns a price below 1" do
      cheap_resource = build(:resource, base_price_min: 1, base_price_max: 2, price_volatility: 100)
      prices = 100.times.map { cheap_resource.generate_market_price }
      expect(prices.min).to be >= 1.0
    end

    context "with low volatility" do
      let(:stable_resource) { build(:resource, base_price_min: 100, base_price_max: 500, price_volatility: 10) }

      it "generates prices closer to the base range" do
        prices = 50.times.map { stable_resource.generate_market_price }
        # With 10% volatility, prices should mostly stay within or near base range
        expect(prices.min).to be >= 50
        expect(prices.max).to be <= 600
      end
    end

    context "with high volatility" do
      let(:volatile_resource) { build(:resource, base_price_min: 100, base_price_max: 500, price_volatility: 90) }

      it "can generate prices significantly outside base range" do
        prices = 100.times.map { volatile_resource.generate_market_price }
        # With 90% volatility, expect wider price swings
        price_range = prices.max - prices.min
        expect(price_range).to be > 300
      end
    end
  end

  describe "custom validations" do
    describe "max_price_greater_than_min_price" do
      it "is invalid when max price equals min price" do
        resource = build(:resource, base_price_min: 100, base_price_max: 100)
        expect(resource).not_to be_valid
        expect(resource.errors[:base_price_max]).to include("must be greater than minimum price")
      end

      it "is invalid when max price is less than min price" do
        resource = build(:resource, base_price_min: 500, base_price_max: 100)
        expect(resource).not_to be_valid
        expect(resource.errors[:base_price_max]).to include("must be greater than minimum price")
      end

      it "is valid when max price is greater than min price" do
        resource = build(:resource, base_price_min: 100, base_price_max: 500)
        expect(resource).to be_valid
      end
    end
  end

  describe "factory traits" do
    it "creates electronics resource" do
      resource = create(:resource, :electronics)
      expect(resource.name).to eq("Electronics")
      expect(resource.price_volatility).to eq(60.00)
    end

    it "creates luxury_goods resource" do
      resource = create(:resource, :luxury_goods)
      expect(resource.name).to eq("Luxury Goods")
      expect(resource.base_price_min).to eq(500.00)
    end

    it "creates raw_materials resource" do
      resource = create(:resource, :raw_materials)
      expect(resource.inventory_size).to eq(5)
    end

    it "creates food_produce resource" do
      resource = create(:resource, :food_produce)
      expect(resource.price_volatility).to eq(80.00)
    end

    it "creates collectibles resource" do
      resource = create(:resource, :collectibles)
      expect(resource.base_price_max).to eq(5000.00)
    end

    it "creates precious_metals resource" do
      resource = create(:resource, :precious_metals)
      expect(resource.price_volatility).to eq(35.00)
    end

    it "creates high_volatility resource" do
      resource = create(:resource, :high_volatility)
      expect(resource.price_volatility).to eq(85.00)
    end

    it "creates low_volatility resource" do
      resource = create(:resource, :low_volatility)
      expect(resource.price_volatility).to eq(15.00)
    end

    it "creates bulky resource" do
      resource = create(:resource, :bulky)
      expect(resource.inventory_size).to eq(10)
    end

    it "creates compact resource" do
      resource = create(:resource, :compact)
      expect(resource.inventory_size).to eq(1)
    end
  end
end
