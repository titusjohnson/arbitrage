# == Schema Information
#
# Table name: events
#
#  id               :integer          not null, primary key
#  name             :string           not null
#  description      :text
#  day_start        :integer
#  duration         :integer
#  active           :boolean          default(FALSE)
#  resource_effects :json
#  location_effects :json
#  event_type       :string
#  severity         :integer
#  rarity           :string
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#
require 'rails_helper'

RSpec.describe Event, type: :model do
  describe "associations" do
    it "has many game_events" do
      event = create(:event)
      game_event1 = create(:game_event, event: event)
      game_event2 = create(:game_event, event: event)

      expect(event.game_events).to match_array([ game_event1, game_event2 ])
    end

    it "has many games through game_events" do
      event = create(:event)
      game1 = create(:game)
      game2 = create(:game)
      create(:game_event, event: event, game: game1)
      create(:game_event, event: event, game: game2)

      expect(event.games).to match_array([ game1, game2 ])
    end

    it "destroys dependent game_events when destroyed" do
      event = create(:event)
      game_event = create(:game_event, event: event)

      expect { event.destroy }.to change { GameEvent.count }.by(-1)
    end
  end

  describe "validations" do
    describe "name" do
      it "is required" do
        event = build(:event, name: nil)
        expect(event).not_to be_valid
        expect(event.errors[:name]).to include("can't be blank")
      end

      it "accepts valid name" do
        event = build(:event, name: "Test Event")
        expect(event).to be_valid
      end
    end

    describe "rarity" do
      it "validates inclusion in RARITIES" do
        event = build(:event, rarity: "invalid")
        expect(event).not_to be_valid
        expect(event.errors[:rarity]).to include("is not included in the list")
      end

      it "accepts valid rarity values" do
        Event::RARITIES.each do |rarity|
          event = build(:event, rarity: rarity)
          expect(event).to be_valid
        end
      end

      it "rejects invalid rarity values" do
        event = build(:event, rarity: "invalid")
        expect(event).not_to be_valid
        expect(event.errors[:rarity]).to include("is not included in the list")
      end
    end

    describe "event_type" do
      it "accepts valid event types" do
        Event::EVENT_TYPES.each do |type|
          event = build(:event, event_type: type)
          expect(event).to be_valid
        end
      end

      it "accepts nil event_type" do
        event = build(:event, event_type: nil)
        expect(event).to be_valid
      end

      it "rejects invalid event types" do
        event = build(:event, event_type: "invalid")
        expect(event).not_to be_valid
        expect(event.errors[:event_type]).to include("is not included in the list")
      end
    end

    describe "severity" do
      it "accepts values in SEVERITY_RANGE" do
        (1..5).each do |severity|
          event = build(:event, severity: severity)
          expect(event).to be_valid
        end
      end

      it "accepts nil severity" do
        event = build(:event, severity: nil)
        expect(event).to be_valid
      end

      it "rejects severity below 1" do
        event = build(:event, severity: 0)
        expect(event).not_to be_valid
      end

      it "rejects severity above 5" do
        event = build(:event, severity: 6)
        expect(event).not_to be_valid
      end

      it "rejects non-integer severity" do
        event = build(:event, severity: 2.5)
        expect(event).not_to be_valid
      end
    end

    describe "duration" do
      it "accepts values in DURATION_RANGE" do
        (1..7).each do |duration|
          event = build(:event, duration: duration)
          expect(event).to be_valid
        end
      end

      it "accepts nil duration" do
        event = build(:event, duration: nil)
        expect(event).to be_valid
      end

      it "rejects duration below 1" do
        event = build(:event, duration: 0)
        expect(event).not_to be_valid
      end

      it "rejects duration above 7" do
        event = build(:event, duration: 8)
        expect(event).not_to be_valid
      end

      it "rejects non-integer duration" do
        event = build(:event, duration: 3.5)
        expect(event).not_to be_valid
      end
    end

    describe "day_start" do
      it "accepts valid day values (1-30)" do
        [ 1, 15, 30 ].each do |day|
          event = build(:event, day_start: day)
          expect(event).to be_valid
        end
      end

      it "accepts nil day_start" do
        event = build(:event, day_start: nil)
        expect(event).to be_valid
      end

      it "rejects day_start below 1" do
        event = build(:event, day_start: 0)
        expect(event).not_to be_valid
      end

      it "rejects day_start above 30" do
        event = build(:event, day_start: 31)
        expect(event).not_to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active events" do
        active_event = create(:event, :active)
        inactive_event = create(:event, active: false)

        expect(Event.active).to eq([ active_event ])
      end
    end

    describe ".by_rarity" do
      it "returns events of specified rarity" do
        common_event = create(:event, :common)
        rare_event = create(:event, :rare)

        expect(Event.by_rarity("common")).to eq([ common_event ])
        expect(Event.by_rarity("rare")).to eq([ rare_event ])
      end
    end

    describe ".by_type" do
      it "returns events of specified type" do
        market_event = create(:event, :market)
        weather_event = create(:event, :weather)

        expect(Event.by_type("market")).to eq([ market_event ])
        expect(Event.by_type("weather")).to eq([ weather_event ])
      end
    end
  end

  describe "constants" do
    it "defines RARITIES" do
      expect(Event::RARITIES).to eq(%w[common uncommon rare ultra_rare exceptional])
    end

    it "defines EVENT_TYPES" do
      expect(Event::EVENT_TYPES).to eq(%w[market weather political cultural])
    end

    it "defines SEVERITY_RANGE" do
      expect(Event::SEVERITY_RANGE).to eq(1..5)
    end

    it "defines DURATION_RANGE" do
      expect(Event::DURATION_RANGE).to eq(1..7)
    end
  end

  describe "factory traits" do
    it "creates common event" do
      event = create(:event, :common)
      expect(event.rarity).to eq("common")
      expect(event.severity).to be_between(1, 2)
      expect(event.duration).to be_between(1, 3)
    end

    it "creates uncommon event" do
      event = create(:event, :uncommon)
      expect(event.rarity).to eq("uncommon")
      expect(event.severity).to be_between(2, 3)
      expect(event.duration).to be_between(2, 4)
    end

    it "creates rare event" do
      event = create(:event, :rare)
      expect(event.rarity).to eq("rare")
      expect(event.severity).to be_between(3, 4)
      expect(event.duration).to be_between(3, 5)
    end

    it "creates ultra_rare event" do
      event = create(:event, :ultra_rare)
      expect(event.rarity).to eq("ultra_rare")
      expect(event.severity).to be_between(4, 5)
      expect(event.duration).to be_between(4, 6)
    end

    it "creates exceptional event" do
      event = create(:event, :exceptional)
      expect(event.rarity).to eq("exceptional")
      expect(event.severity).to eq(5)
      expect(event.duration).to be_between(5, 7)
    end

    it "creates active event" do
      event = create(:event, :active)
      expect(event.active).to be true
    end

    it "creates market event" do
      event = create(:event, :market)
      expect(event.event_type).to eq("market")
    end

    it "creates weather event" do
      event = create(:event, :weather)
      expect(event.event_type).to eq("weather")
    end

    it "creates political event" do
      event = create(:event, :political)
      expect(event.event_type).to eq("political")
    end

    it "creates cultural event" do
      event = create(:event, :cultural)
      expect(event.event_type).to eq("cultural")
    end

    it "creates event with resource effects" do
      event = create(:event, :with_resource_effects)
      expect(event.resource_effects).to have_key("price_modifiers")
      expect(event.resource_effects).to have_key("availability_modifiers")
    end

    it "creates event with location effects" do
      event = create(:event, :with_location_effects)
      expect(event.location_effects).to have_key("access_restrictions")
    end
  end

  describe "JSON fields" do
    it "stores resource_effects as JSON" do
      effects = {
        "price_modifiers" => [
          {
            "tags" => ["food"],
            "match" => "any",
            "multiplier" => 1.5
          }
        ]
      }
      event = create(:event, resource_effects: effects)
      event.reload

      expect(event.resource_effects).to eq(effects)
    end

    it "stores location_effects as JSON" do
      effects = {
        "quantity_modifiers" => [
          {
            "scoped_tags" => {
              "location" => ["port_city"],
              "resource" => ["food"]
            },
            "multiplier" => 0.5
          }
        ]
      }
      event = create(:event, location_effects: effects)
      event.reload

      expect(event.location_effects).to eq(effects)
    end
  end
end
