class GamesController < ApplicationController
  skip_before_action :load_or_redirect_to_difficulty_selection, only: [ :new, :create ]

  def new
    if find_game_by_restore_key
      redirect_to root_path
      return
    end

    @difficulties = Game.difficulties_for_display
  end

  def create
    difficulty = params[:difficulty]&.to_sym

    unless Game.difficulty_options.include?(difficulty)
      redirect_to new_game_path, alert: "Please select a valid difficulty."
      return
    end

    @current_game = create_new_game(difficulty: difficulty)
    redirect_to root_path, notice: "Game started on #{@current_game.difficulty_display_name} difficulty!"
  end

  def abandon
    if current_game
      current_game.end_game!
      clear_game_session
    end

    redirect_to new_game_path, notice: "Game abandoned. Start a new adventure!"
  end
end
