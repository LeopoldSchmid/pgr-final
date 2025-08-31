class DateProposalVotesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_date_proposal_vote, only: [:update, :destroy]

  def create
    @date_proposal = @trip.date_proposals.find(params[:date_proposal_vote][:date_proposal_id])
    @date_proposal_vote = @date_proposal.date_proposal_votes.find_or_initialize_by(user: Current.user)
    
    @date_proposal_vote.vote_type = params[:date_proposal_vote][:vote_type]

    if @date_proposal_vote.save
      render json: { 
        status: 'success', 
        vote: @date_proposal_vote.vote_type,
        vote_summary: @date_proposal.vote_summary
      }
    else
      render json: { 
        status: 'error', 
        errors: @date_proposal_vote.errors 
      }, status: :unprocessable_entity
    end
  end

  def update
    if @date_proposal_vote.update(vote_params)
      render json: { 
        status: 'success', 
        vote: @date_proposal_vote.vote_type,
        vote_summary: @date_proposal_vote.date_proposal.vote_summary
      }
    else
      render json: { 
        status: 'error', 
        errors: @date_proposal_vote.errors 
      }, status: :unprocessable_entity
    end
  end

  def destroy
    @date_proposal_vote.destroy
    render json: { 
      status: 'success', 
      vote_summary: @date_proposal_vote.date_proposal.vote_summary 
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

  def set_date_proposal_vote
    @date_proposal_vote = DateProposalVote.joins(date_proposal: :trip)
                                          .where(trips: { id: @trip.id }, user: Current.user)
                                          .find(params[:id])
  end

  def vote_params
    params.require(:date_proposal_vote).permit(:vote_type)
  end
end