class HomeController < ApplicationController
  before_action :require_authentication, except: [:index]

  def index
    if authenticated?
      # Show dashboard for logged-in users with trip data (overview tab)
      load_all_trips
      @planning_trips = @all_trips.select(&:planning?).sort_by(&:created_at).reverse
      @active_trips = @all_trips.select(&:active?).sort_by { |t| t.start_date || Time.current }
      @completed_trips = @all_trips.select(&:completed?).sort_by { |t| t.end_date || Time.current }.reverse.first(5)
    else
      # Show landing page for guests
    end
  end

  # Secondary nav: Calendar view
  def calendar
    load_all_trips
    # Calendar view implementation
    @calendar_events = []
    @all_trips.each do |trip|
      if trip.start_date && trip.end_date
        @calendar_events << {
          title: trip.name,
          start: trip.start_date,
          end: trip.end_date,
          url: trip_overview_path # This will use trip context
        }
      end
    end
  end

  # Secondary nav: Upcoming trips
  def upcoming
    load_all_trips
    @upcoming_trips = @all_trips
                      .select { |t| t.start_date && t.start_date >= Date.today }
                      .sort_by(&:start_date)
  end

  private

  def load_all_trips
    # Load trips user owns + trips user is a member of
    owned_trips = Current.user.trips
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user })
    @all_trips = (owned_trips + member_trips).uniq
  end
end