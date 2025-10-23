class TripSwitcherController < ApplicationController
  before_action :require_authentication

  # GET /select_trip
  def index
    # Get all trips user owns or is a member of
    @owned_trips = Current.user.trips.order(created_at: :desc)
    @member_trips = Trip.joins(:trip_members)
                        .where(trip_members: { user: Current.user })
                        .order(created_at: :desc)

    @all_trips = (@owned_trips.to_a + @member_trips.to_a).uniq.sort_by(&:created_at).reverse

    # Categorize trips
    @planning_trips = @all_trips.select { |t| t.status == 'planning' }
    @active_trips = @all_trips.select { |t| t.status == 'active' }
    @completed_trips = @all_trips.select { |t| t.status == 'completed' }

    @current_trip_id = session[:current_trip_id]
    @return_to = params[:return_to]
  end

  # PATCH /switch_trip
  def update
    trip = Trip.find_by(id: params[:trip_id])

    # Verify user has access to this trip
    unless trip && (trip.user == Current.user || trip.has_member?(Current.user))
      flash[:alert] = "You don't have access to this trip."
      redirect_to select_trip_path and return
    end

    set_current_trip(trip)

    return_path = if params[:return_to].present?
                    return_to = params[:return_to]
                    if return_to.start_with?('/')
                      return_to
                    else
                      "/#{return_to}"
                    end
                  else
                    trip_path(trip)
                  end
    redirect_to return_path, notice: "Switched to #{trip.name}"
  end

  # DELETE /clear_trip_context
  def destroy
    clear_trip_context
    redirect_to root_path, notice: "Trip context cleared"
  end
end
