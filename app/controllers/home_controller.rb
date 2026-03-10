class HomeController < ApplicationController
  def index
    @featured_events = Event.published.upcoming.limit(6)
  end
end
