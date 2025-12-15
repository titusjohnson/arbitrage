module GameSessionHelper
  def sign_in_with_game(game)
    # Mock the session lookup to return the game
    allow_any_instance_of(ApplicationController).to receive(:find_game_by_restore_key).and_return(game)
  end
end

RSpec.configure do |config|
  config.include GameSessionHelper, type: :request
end
