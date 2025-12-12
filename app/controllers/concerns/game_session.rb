module GameSession
  extend ActiveSupport::Concern

  included do
    before_action :load_or_create_game
    helper_method :current_game
  end

  private

  def current_game
    @current_game
  end

  def load_or_create_game
    @current_game = find_game_by_restore_key || create_new_game
  end

  def find_game_by_restore_key
    return nil unless session[:game_restore_key]
    Game.find_by(restore_key: session[:game_restore_key])
  end

  def create_new_game
    game = Game.create!
    session[:game_restore_key] = game.restore_key
    game
  end
end
