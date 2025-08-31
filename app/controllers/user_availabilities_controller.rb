class UserAvailabilitiesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_user_availability, only: [:update, :destroy]

  def index
    @user_availabilities = Current.user.user_availabilities.order(:start_date)
    render json: @user_availabilities
  end

  def create
    @user_availability = Current.user.user_availabilities.build(user_availability_params)

    if @user_availability.save
      render json: { 
        status: 'success', 
        availability: @user_availability,
        message: 'Availability period added successfully'
      }
    else
      render json: { 
        status: 'error', 
        errors: @user_availability.errors 
      }, status: :unprocessable_entity
    end
  end

  def update
    if @user_availability.update(user_availability_params)
      render json: { 
        status: 'success', 
        availability: @user_availability,
        message: 'Availability period updated successfully'
      }
    else
      render json: { 
        status: 'error', 
        errors: @user_availability.errors 
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @user_availability.destroy
    render json: { 
      status: 'success', 
      message: 'Availability period removed successfully'
    }
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    # Check if user is a member
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, id: params[:trip_id])
    @trip = member_trips.first
    
    unless @trip
      render json: { error: "Trip not found or access denied" }, status: :not_found
    end
  end

  def set_user_availability
    @user_availability = Current.user.user_availabilities.find(params[:id])
  end

  def user_availability_params
    params.require(:user_availability).permit(:start_date, :end_date, :availability_type, :title, :description, :recurring)
  end
end