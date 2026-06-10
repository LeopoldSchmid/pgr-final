class Api::BaseController < ApplicationController
  private

  def set_accessible_trip
    @trip = Current.user.all_trips.find(params[:trip_id])
  rescue ActiveRecord::RecordNotFound
    render json: { error: "Trip not found or access denied" }, status: :not_found
  end

  def require_expense_management
    return if performed?
    return if @trip.user_can_manage_expenses?(Current.user)

    render json: { error: "You do not have permission to manage expenses for this trip." }, status: :forbidden
  end
end
