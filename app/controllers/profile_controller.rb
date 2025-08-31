class ProfileController < ApplicationController
  before_action :require_authentication

  def show
    @user = Current.user
    @user_stats = {
      total_trips: user_trips_count,
      completed_trips: user_completed_trips_count,
      journal_entries: user_journal_entries_count,
      favorite_locations: user_favorite_locations_count
    }
  end

  private

  def user_trips_count
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips.count
    member_trips = Trip.joins(:trip_members).where(trip_members: { user: Current.user }).distinct.count
    owned_trips + member_trips
  end

  def user_completed_trips_count
    owned_trips = Current.user.trips.completed.count
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, status: 'completed')
                      .distinct.count
    owned_trips + member_trips
  end

  def user_journal_entries_count
    Current.user.journal_entries.count
  end

  def user_favorite_locations_count
    Current.user.journal_entries.where(global_favorite: true).count
  end
end