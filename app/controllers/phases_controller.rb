class PhasesController < ApplicationController
  before_action :require_authentication
  
  def plan
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user })
    all_trips = (owned_trips + member_trips).uniq
    @planning_trips = all_trips.select(&:planning?).sort_by(&:created_at).reverse

    # Templates from completed trips (owned only for now)
    @recent_templates = Current.user.trips.select(&:completed?).first(3)
  end

  def go
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user })
    all_trips = (owned_trips + member_trips).uniq
    @active_trips = all_trips.select(&:active?).sort_by { |t| t.start_date || Time.current }.reverse
  end

  def reminisce
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user })
    all_trips = (owned_trips + member_trips).uniq
    @completed_trips = all_trips.select(&:completed?).sort_by { |t| t.end_date || Time.current }.reverse
  end
end
