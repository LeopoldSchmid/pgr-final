class SearchController < ApplicationController
  before_action :require_authentication

  def index
    @query = params[:query]
    if @query.present?
      # Search trips
      @trips = Current.user.trips.where("LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", "%#{@query}%", "%#{@query}%")

      # Search journal entries
      @journal_entries = JournalEntry.joins(:trip)
                                     .where(trips: { user_id: Current.user.id })
                                     .where("LOWER(journal_entries.content) LIKE LOWER(?) OR LOWER(journal_entries.location) LIKE LOWER(?)", "%#{@query}%", "%#{@query}%")
    else
      @trips = []
      @journal_entries = []
    end
  end
end