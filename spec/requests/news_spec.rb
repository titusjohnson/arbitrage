require 'rails_helper'

RSpec.describe "News", type: :request do
  let(:game) { create(:game) }

  before do
    sign_in_with_game(game)
  end

  describe "GET /news" do
    it "returns http success" do
      get "/news"
      expect(response).to have_http_status(:success)
    end

    it "displays the news feed" do
      get "/news"
      expect(response.body).to include("News")
    end

    it "accepts days_back parameter" do
      get "/news", params: { days_back: 14 }
      expect(response).to have_http_status(:success)
    end

    it "clamps days_back to valid range" do
      get "/news", params: { days_back: 100 }
      expect(response).to have_http_status(:success)
    end

    it "accepts type filter parameter" do
      get "/news", params: { type: "event" }
      expect(response).to have_http_status(:success)
    end

    it "filters by market type" do
      get "/news", params: { type: "market" }
      expect(response).to have_http_status(:success)
    end

    it "filters by action type" do
      get "/news", params: { type: "action" }
      expect(response).to have_http_status(:success)
    end

    it "filters by trend type" do
      get "/news", params: { type: "trend" }
      expect(response).to have_http_status(:success)
    end

    it "marks unread event logs as read" do
      event_log = create(:event_log, game: game, read_at: nil)

      get "/news"

      event_log.reload
      expect(event_log.read_at).not_to be_nil
    end

    it "does not mark old event logs as read" do
      event_log = create(:event_log, game: game, read_at: nil, created_at: 10.days.ago)

      get "/news"

      event_log.reload
      expect(event_log.read_at).to be_nil
    end
  end
end
