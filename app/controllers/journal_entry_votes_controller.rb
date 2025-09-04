class JournalEntryVotesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :authorize_member
  before_action :set_journal_entry

  def create
    existing_vote = @journal_entry.discussion_votes.find_by(user: Current.user)
    
    if existing_vote
      # Toggle like - if already liked, unlike it
      existing_vote.destroy
      liked = false
    else
      # Create new like (only upvotes for Instagram-style likes)
      @journal_entry.discussion_votes.create!(user: Current.user, vote_type: 'upvote')
      liked = true
    end

    respond_to do |format|
      format.json { 
        render json: { 
          liked: liked, 
          likes_count: @journal_entry.likes_count 
        } 
      }
      format.html { redirect_to journal_trip_path(@trip) }
    end
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def authorize_member
    unless @trip.has_member?(Current.user)
      redirect_to root_path, alert: 'You are not a member of this trip.'
    end
  end

  def set_journal_entry
    @journal_entry = @trip.journal_entries.find(params[:journal_entry_id])
  end
end