class AboutController < ApplicationController
  skip_before_action :load_or_redirect_to_difficulty_selection

  def index
  end
end
