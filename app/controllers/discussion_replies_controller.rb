class DiscussionRepliesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip_and_post
  before_action :set_discussion_reply, only: [:destroy, :upvote, :downvote]
  before_action :verify_trip_access
  before_action :verify_reply_ownership, only: [:destroy]

  def create
    @discussion_reply = @discussion_post.discussion_replies.build(discussion_reply_params)
    @discussion_reply.user = Current.user

    if @discussion_reply.save
      redirect_to trip_discussion_path(@trip, @discussion_post), notice: t('discussion_replies.created')
    else
      @discussion_replies = @discussion_post.discussion_replies.includes(:user).oldest_first
      @new_reply = @discussion_reply
      render 'discussions/show', status: :unprocessable_entity
    end
  end

  def destroy
    @discussion_reply.destroy
    redirect_to trip_discussion_path(@trip, @discussion_post), notice: t('discussion_replies.deleted')
  end

  def upvote
    vote_for_reply('upvote')
  end

  def downvote
    vote_for_reply('downvote')
  end

  private

  def set_trip_and_post
    @trip = Trip.find(params[:trip_id])
    @discussion_post = @trip.discussion_posts.find(params[:discussion_id])
  end

  def set_discussion_reply
    @discussion_reply = @discussion_post.discussion_replies.find(params[:id])
  end

  def verify_trip_access
    redirect_to trips_path unless @trip.has_member?(Current.user)
  end

  def verify_reply_ownership
    redirect_to trip_discussion_path(@trip, @discussion_post) unless @discussion_reply.user == Current.user
  end

  def discussion_reply_params
    params.require(:discussion_reply).permit(:content, :parent_id)
  end
  
  def vote_for_reply(vote_type)
    existing_vote = @discussion_reply.discussion_votes.find_by(user: Current.user)
    
    if existing_vote
      if existing_vote.vote_type == vote_type
        # User clicked same vote type - remove vote
        existing_vote.destroy
      else
        # User clicked different vote type - change vote
        existing_vote.update!(vote_type: vote_type)
      end
    else
      # Create new vote
      @discussion_reply.discussion_votes.create!(user: Current.user, vote_type: vote_type)
    end
    
    redirect_to trip_discussion_path(@trip, @discussion_post)
  end
end