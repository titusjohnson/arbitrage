class EventLogsController < ApplicationController
  def index
    @event_logs = current_game.event_logs.chronological
  end
end
