class MemoriesController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context

  def index
    @trip = current_trip

    # Load memories (journal entries and attachments) for the current trip
    @journal_entries = @trip.journal_entries
                            .includes(:user, :comments, :trip_attachment_votes)
                            .order(entry_date: :desc, created_at: :desc)

    @trip_attachments = @trip.trip_attachments
                             .includes(:user, :trip_attachment_comments, :trip_attachment_votes)
                             .order(created_at: :desc)

    # Merge and sort by date for unified timeline
    all_memories = (@journal_entries.to_a + @trip_attachments.to_a)
                     .sort_by { |m| m.try(:entry_date) || m.created_at }
                     .reverse

    @memories = all_memories.first(50) # Show last 50 memories

    # Count stats for overview
    @total_entries = @trip.journal_entries.count
    @total_photos = @trip.trip_attachments.count
    @favorite_moments = @trip.journal_entries.favorites.count
    @locations_visited = @trip.journal_entries.where.not(location: [nil, '']).distinct.count(:location)
  end

  private

  def ensure_trip_context
    unless current_trip
      flash[:alert] = t('memories.errors.no_trip_selected')
      redirect_to select_trip_path(return_to: memories_path)
    end
  end
end
