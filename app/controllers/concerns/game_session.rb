module GameSession
  extend ActiveSupport::Concern

  included do
    before_action :load_or_redirect_to_difficulty_selection
    helper_method :current_game
  end

  private

  def current_game
    @current_game
  end

  def load_or_redirect_to_difficulty_selection
    @current_game = find_game_by_restore_key

    unless @current_game
      redirect_to new_game_path unless self.class.name == "GamesController"
    end
  end

  def find_game_by_restore_key
    return nil unless session[:game_restore_key]
    Game.active.find_by(restore_key: session[:game_restore_key])
  end

  def create_new_game(difficulty:)
    game = Game.create_with_difficulty!(difficulty)
    session[:game_restore_key] = game.restore_key
    game
  end

  def clear_game_session
    session.delete(:game_restore_key)
    @current_game = nil
  end
end
