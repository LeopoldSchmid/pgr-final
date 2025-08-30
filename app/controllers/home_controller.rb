class HomeController < ApplicationController
  def index
    if authenticated?
      # Show dashboard for logged-in users with trip data
      @current_user = Current.user
      
      # Load trips user owns + trips user is a member of
      owned_trips = Current.user.trips
      member_trips = Trip.joins(:trip_members)
                        .where(trip_members: { user: Current.user })
      all_trips = (owned_trips + member_trips).uniq
      
      # Categorize trips by status
      @planning_trips = all_trips.select { |t| t.status == 'planning' }.sort_by(&:created_at).reverse
      @active_trips = all_trips.select { |t| t.status == 'active' }.sort_by(&:start_date || Time.current).reverse  
      @completed_trips = all_trips.select { |t| t.status == 'completed' }.sort_by(&:end_date || Time.current).reverse
    else
      # Show landing page for guests
    end
  end
end