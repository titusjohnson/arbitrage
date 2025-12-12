# == Schema Information
#
# Table name: game_events
#
#  id             :integer          not null, primary key
#  game_id        :integer          not null
#  event_id       :integer          not null
#  day_triggered  :integer
#  days_remaining :integer
#  seen           :boolean          default(FALSE)
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#
# Indexes
#
#  index_game_events_on_event_id  (event_id)
#  index_game_events_on_game_id   (game_id)
#
# Foreign Keys
#
#  event_id  (events.id)
#  game_id   (games.id)
#
require 'rails_helper'

RSpec.describe GameEvent, type: :model do
  describe "associations" do
    it "belongs to game" do
      game_event = create(:game_event)
      expect(game_event.game).to be_a(Game)
    end

    it "belongs to event" do
      game_event = create(:game_event)
      expect(game_event.event).to be_a(Event)
    end

    it "is invalid without a game" do
      game_event = build(:game_event, game: nil)
      expect(game_event).not_to be_valid
    end

    it "is invalid without an event" do
      game_event = build(:game_event, event: nil)
      expect(game_event).not_to be_valid
    end
  end

  describe "validations" do
    describe "day_triggered" do
      it "accepts valid day values (1-30)" do
        [ 1, 15, 30 ].each do |day|
          game_event = build(:game_event, day_triggered: day)
          expect(game_event).to be_valid
        end
      end

      it "accepts nil day_triggered" do
        game_event = build(:game_event, day_triggered: nil)
        expect(game_event).to be_valid
      end

      it "rejects day_triggered below 1" do
        game_event = build(:game_event, day_triggered: 0)
        expect(game_event).not_to be_valid
      end

      it "rejects day_triggered above 30" do
        game_event = build(:game_event, day_triggered: 31)
        expect(game_event).not_to be_valid
      end

      it "rejects non-integer day_triggered" do
        game_event = build(:game_event, day_triggered: 5.5)
        expect(game_event).not_to be_valid
      end
    end

    describe "days_remaining" do
      it "accepts valid days_remaining values" do
        [ 0, 1, 5, 7 ].each do |days|
          game_event = build(:game_event, days_remaining: days)
          expect(game_event).to be_valid
        end
      end

      it "accepts nil days_remaining" do
        game_event = build(:game_event, days_remaining: nil)
        expect(game_event).to be_valid
      end

      it "rejects negative days_remaining" do
        game_event = build(:game_event, days_remaining: -1)
        expect(game_event).not_to be_valid
      end

      it "rejects non-integer days_remaining" do
        game_event = build(:game_event, days_remaining: 2.5)
        expect(game_event).not_to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns game events with days_remaining > 0" do
        active_game_event = create(:game_event, days_remaining: 3)
        expired_game_event = create(:game_event, days_remaining: 0)
        nil_game_event = create(:game_event, days_remaining: nil)

        expect(GameEvent.active).to eq([ active_game_event ])
      end
    end

    describe ".expired" do
      it "returns game events with days_remaining = 0" do
        active_game_event = create(:game_event, days_remaining: 3)
        expired_game_event = create(:game_event, days_remaining: 0)

        expect(GameEvent.expired).to eq([ expired_game_event ])
      end
    end

    describe ".unseen" do
      it "returns game events that have not been seen" do
        seen_game_event = create(:game_event, seen: true)
        unseen_game_event = create(:game_event, seen: false)

        expect(GameEvent.unseen).to eq([ unseen_game_event ])
      end
    end
  end

  describe "#active?" do
    it "returns true when days_remaining > 0" do
      game_event = build(:game_event, days_remaining: 3)
      expect(game_event.active?).to be true
    end

    it "returns false when days_remaining = 0" do
      game_event = build(:game_event, days_remaining: 0)
      expect(game_event.active?).to be false
    end

    it "returns false when days_remaining is nil" do
      game_event = build(:game_event, days_remaining: nil)
      expect(game_event.active?).to be false
    end
  end

  describe "#expired?" do
    it "returns true when days_remaining = 0" do
      game_event = build(:game_event, days_remaining: 0)
      expect(game_event.expired?).to be true
    end

    it "returns false when days_remaining > 0" do
      game_event = build(:game_event, days_remaining: 3)
      expect(game_event.expired?).to be false
    end

    it "returns false when days_remaining is nil" do
      game_event = build(:game_event, days_remaining: nil)
      expect(game_event.expired?).to be false
    end
  end

  describe "#decrement_days!" do
    it "decrements days_remaining by 1" do
      game_event = create(:game_event, days_remaining: 3)
      expect { game_event.decrement_days! }.to change { game_event.reload.days_remaining }.from(3).to(2)
    end

    it "does not decrement when days_remaining is 0" do
      game_event = create(:game_event, days_remaining: 0)
      expect { game_event.decrement_days! }.not_to change { game_event.reload.days_remaining }
    end

    it "does not decrement when days_remaining is nil" do
      game_event = create(:game_event, days_remaining: nil)
      expect { game_event.decrement_days! }.not_to change { game_event.reload.days_remaining }
    end

    it "can decrement from 1 to 0" do
      game_event = create(:game_event, days_remaining: 1)
      expect { game_event.decrement_days! }.to change { game_event.reload.days_remaining }.from(1).to(0)
    end

    it "updates the record in the database" do
      game_event = create(:game_event, days_remaining: 5)
      game_event.decrement_days!

      expect(GameEvent.find(game_event.id).days_remaining).to eq(4)
    end
  end

  describe "factory traits" do
    it "creates active game_event" do
      game_event = create(:game_event, :active)
      expect(game_event.days_remaining).to be > 0
      expect(game_event.active?).to be true
    end

    it "creates expired game_event" do
      game_event = create(:game_event, :expired)
      expect(game_event.days_remaining).to eq(0)
      expect(game_event.expired?).to be true
    end

    it "creates seen game_event" do
      game_event = create(:game_event, :seen)
      expect(game_event.seen).to be true
    end

    it "creates unseen game_event" do
      game_event = create(:game_event, :unseen)
      expect(game_event.seen).to be false
    end
  end

  describe "integration with Game and Event" do
    it "creates a valid game_event with associations" do
      game = create(:game)
      event = create(:event)
      game_event = create(:game_event, game: game, event: event)

      expect(game_event.game).to eq(game)
      expect(game_event.event).to eq(event)
      expect(game.game_events).to include(game_event)
      expect(event.game_events).to include(game_event)
    end

    it "allows multiple events per game" do
      game = create(:game)
      event1 = create(:event, name: "Event 1")
      event2 = create(:event, name: "Event 2")

      game_event1 = create(:game_event, game: game, event: event1)
      game_event2 = create(:game_event, game: game, event: event2)

      expect(game.game_events.count).to eq(2)
      expect(game.events).to match_array([ event1, event2 ])
    end

    it "allows same event in multiple games" do
      game1 = create(:game)
      game2 = create(:game)
      event = create(:event)

      game_event1 = create(:game_event, game: game1, event: event)
      game_event2 = create(:game_event, game: game2, event: event)

      expect(event.game_events.count).to eq(2)
      expect(event.games).to match_array([ game1, game2 ])
    end
  end
end
