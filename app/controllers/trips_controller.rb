class TripsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip, only: [:show, :edit, :update, :destroy, :plan, :go, :reminisce]

  def index
    @trips = Current.user.trips.order(created_at: :desc)
  end

  def show
    # Redirect to appropriate phase view
    redirect_to send("#{@trip.current_phase}_trip_path", @trip)
  end

  def new
    @trip = Current.user.trips.build(status: 'planning')
  end

  def create
    @trip = Current.user.trips.build(trip_params)
    @trip.status = 'planning'
    
    if @trip.save
      redirect_to plan_trip_path(@trip), notice: 'Trip created successfully!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @trip.update(trip_params)
      redirect_to @trip, notice: 'Trip updated successfully!'
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @trip.destroy
    redirect_to trips_path, notice: 'Trip deleted successfully!'
  end

  # Trip-level phase views
  def plan
    # Trip planning view - dates, destinations, meals, etc.
  end

  def go
    # Trip execution view - shopping lists, expenses, day-of activities
  end

  def reminisce
    # Trip memories view - photos, summaries, templates
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:id])
  end

  def trip_params
    params.require(:trip).permit(:name, :description, :start_date, :end_date, :status)
  end
end
