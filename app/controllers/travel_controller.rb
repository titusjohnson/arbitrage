class TravelController < ApplicationController
  def index
    @locations = Location.all.order(:name)
  end
end
