require 'rails_helper'

RSpec.describe "EventLogs", type: :request do
  let(:game) { create(:game) }

  before do
    # Simulate the game session
    allow_any_instance_of(EventLogsController).to receive(:current_game).and_return(game)
  end

  describe "GET /log" do
    it "returns http success" do
      get "/log"
      expect(response).to have_http_status(:success)
    end

    it "displays event logs in chronological order" do
      old_log = create(:event_log, :without_loggable, game: game, message: "First event", created_at: 2.days.ago)
      new_log = create(:event_log, :without_loggable, game: game, message: "Second event", created_at: 1.day.ago)

      get "/log"

      expect(response.body).to include("First event")
      expect(response.body).to include("Second event")
      # First event should appear before second event in the HTML
      expect(response.body.index("First event")).to be < response.body.index("Second event")
    end
  end
end
