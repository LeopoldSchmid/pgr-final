class JournalEntriesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_journal_entry, only: [:update, :destroy, :toggle_favorite]

  def create
    @journal_entry = @trip.journal_entries.build(journal_entry_params)
    @journal_entry.user = Current.user
    @journal_entry.entry_date ||= Date.current
    
    if @journal_entry.save
      redirect_to go_trip_path(@trip), notice: 'Journal entry added! 📝'
    else
      redirect_to go_trip_path(@trip), alert: 'Could not save journal entry.'
    end
  end

  def update
    if @journal_entry.update(journal_entry_params)
      redirect_to go_trip_path(@trip), notice: 'Journal entry updated! ✏️'
    else
      redirect_to go_trip_path(@trip), alert: 'Could not update journal entry.'
    end
  end

  def destroy
    @journal_entry.destroy
    redirect_to go_trip_path(@trip), notice: 'Journal entry deleted! 🗑️'
  end

  def toggle_favorite
    @journal_entry.toggle_favorite!
    status = @journal_entry.favorite? ? 'Added to favorites! ⭐' : 'Removed from favorites'
    redirect_to go_trip_path(@trip), notice: status
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:trip_id])
  end

  def set_journal_entry
    @journal_entry = @trip.journal_entries.find(params[:id])
  end

  def journal_entry_params
    params.require(:journal_entry).permit(:content, :location, :entry_date, :favorite, :latitude, :longitude, :image)
  end
end
