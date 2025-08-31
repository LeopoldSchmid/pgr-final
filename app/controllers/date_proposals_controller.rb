class DateProposalsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_date_proposal, only: [:destroy]

  def index
    @date_proposals = @trip.date_proposals.order(:start_date)
    @new_date_proposal = @trip.date_proposals.build
  end

  def create
    @date_proposal = @trip.date_proposals.build(date_proposal_params)
    @date_proposal.user = Current.user

    if @date_proposal.save
      redirect_to trip_date_proposals_path(@trip), notice: 'Date proposal added!'
    else
      # If validation fails, we need to re-render the plan page with errors
      # This requires fetching other data needed for the plan page
      @related_trips = @trip.series_name.present? ? Trip.in_series(@trip.series_name).where.not(id: @trip.id) : []
      @date_proposals = @trip.date_proposals.order(:start_date) # Need this for plan page
      render 'trips/plan', status: :unprocessable_entity
    end
  end

  def destroy
    @date_proposal.destroy
    redirect_to plan_trip_path(@trip), notice: 'Date proposal deleted!'
  end

  private

  def set_trip
    return render json: { error: "Trip ID required" }, status: :bad_request unless params[:trip_id].present?
    
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

  def set_date_proposal
    @date_proposal = @trip.date_proposals.find(params[:id])
    # Ensure user can only delete their own proposals or if they are an admin/owner
    unless @date_proposal.user == Current.user || @trip.user_can_manage_expenses?(Current.user)
      redirect_to plan_trip_path(@trip), alert: "You are not authorized to delete this date proposal."
    end
  end

  def date_proposal_params
    params.require(:date_proposal).permit(:start_date, :end_date, :description, :notes)
  end
end