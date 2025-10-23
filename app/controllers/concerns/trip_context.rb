module TripContext
  extend ActiveSupport::Concern

  # Set the current trip in the session
  def set_current_trip(trip)
    session[:current_trip_id] = trip&.id
  end

  # Get the current trip from session, with authorization check
  def current_trip
    return nil unless session[:current_trip_id]

    @current_trip ||= begin
      trip_id = session[:current_trip_id]

      # Try to find trip owned by user
      trip = Current.user.trips.find_by(id: trip_id)

      # If not found, check if user is a member
      trip ||= Trip.joins(:trip_members)
                   .where(trip_members: { user: Current.user }, id: trip_id)
                   .first

      # Clear session if trip not found or user doesn't have access
      session[:current_trip_id] = nil unless trip

      trip
    end
  rescue ActiveRecord::RecordNotFound, NoMethodError
    session[:current_trip_id] = nil
    nil
  end

  # Get current trip, or fall back to next scheduled trip
  def current_trip_or_next
    current_trip || next_scheduled_trip
  end

  # Clear the trip context from session
  def clear_trip_context
    session.delete(:current_trip_id)
    @current_trip = nil
  end

  private

  # Find the next scheduled trip for the current user
  # Returns the active trip, or the next trip by start_date
  def next_scheduled_trip
    return nil unless Current.user

    # Get all trips user owns or is a member of
    owned_trips = Current.user.trips
    member_trips = Trip.joins(:trip_members)
                       .where(trip_members: { user: Current.user })

    all_trips = (owned_trips + member_trips).uniq

    # First, check for active trips
    active_trip = all_trips.find { |t| t.status == "active" }
    return active_trip if active_trip

    # Otherwise, find the trip with the earliest start_date in the future
    all_trips
      .select { |t| t.start_date && t.start_date >= Date.current }
      .min_by(&:start_date)
  end
end
