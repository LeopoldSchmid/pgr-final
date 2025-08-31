class FavoriteLocationsController < ApplicationController
  before_action :require_authentication

  def index
    @global_favorite_locations = JournalEntry.global_favorites.with_location.includes(:user).order(entry_date: :desc)
  end
end
