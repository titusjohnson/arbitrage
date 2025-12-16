class LeaderboardController < ApplicationController
  skip_before_action :load_or_redirect_to_difficulty_selection

  def index
    @games = Game.finished
                 .where.not(final_score: nil)
                 .order(final_score: :desc, completed_at: :asc)
                 .limit(100)
  end
end
