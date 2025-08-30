class PhasesController < ApplicationController
  before_action :require_authentication
  
  def plan
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips.planning
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, status: 'planning')
    @planning_trips = (owned_trips + member_trips).uniq.sort_by(&:created_at).reverse
    
    # Templates from completed trips (owned only for now)
    @recent_templates = Current.user.trips.completed.limit(3)
  end

  def go
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips.active
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, status: 'active')
    @active_trips = (owned_trips + member_trips).uniq.sort_by(&:start_date).reverse
  end

  def reminisce
    # Include trips user owns + trips user is a member of
    owned_trips = Current.user.trips.completed
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, status: 'completed')
    @completed_trips = (owned_trips + member_trips).uniq.sort_by(&:end_date).reverse
  end
end
