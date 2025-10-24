class MemoriesController < ApplicationController
  before_action :require_authentication

  def index
    # Default action - shows feed (trip or global context)
    if current_trip
      feed_for_trip
    else
      feed_global
    end
  end

  # Trip context: Feed for current trip
  def feed
    if current_trip
      feed_for_trip
    else
      feed_global
    end
    render :index
  end

  # Trip context: Albums
  def albums
    ensure_trip_context
    @trip = current_trip
    # Albums functionality to be implemented
    @albums = [] # Placeholder
  end

  # Trip context: Map view
  def map
    ensure_trip_context
    @trip = current_trip
    @journal_entries = @trip.journal_entries.with_location.includes(:user)
  end

  # Global context: Favorites
  def favorites
    # Show favorite memories across all trips
    @favorite_entries = JournalEntry.joins(:trip)
                                    .where(trips: { user_id: Current.user.id })
                                    .or(JournalEntry.joins(trip: :trip_members)
                                                    .where(trip_members: { user_id: Current.user.id }))
                                    .where(favorite: true)
                                    .order(created_at: :desc)
                                    .limit(50)
  end

  private

  def feed_for_trip
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
    @favorite_moments = @trip.journal_entries.where(favorite: true).count
    @locations_visited = @trip.journal_entries.where.not(location: [nil, '']).distinct.count(:location)
  end

  def feed_global
    # Show memories across all user's trips
    user_trip_ids = (Current.user.trips.pluck(:id) +
                    Trip.joins(:trip_members).where(trip_members: { user: Current.user }).pluck(:id)).uniq

    @journal_entries = JournalEntry.where(trip_id: user_trip_ids)
                                   .includes(:user, :trip, :comments)
                                   .order(created_at: :desc)
                                   .limit(50)

    @trip_attachments = TripAttachment.joins(:trip)
                                      .where(trip_id: user_trip_ids)
                                      .includes(:user, :trip)
                                      .order(created_at: :desc)
                                      .limit(50)

    all_memories = (@journal_entries.to_a + @trip_attachments.to_a)
                     .sort_by { |m| m.try(:entry_date) || m.created_at }
                     .reverse

    @memories = all_memories.first(50)
    @global_view = true
  end

  def ensure_trip_context
    unless current_trip
      flash[:alert] = t('memories.errors.no_trip_selected')
      redirect_to select_trip_path(return_to: memories_path)
    end
  end
end
