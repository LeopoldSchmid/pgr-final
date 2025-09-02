class DiscussionsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_discussion_post, only: [:show, :edit, :update, :destroy, :upvote, :downvote]
  before_action :verify_trip_access, only: [:index, :show, :new, :create]
  before_action :verify_post_ownership, only: [:edit, :update, :destroy]

  def index
    @discussion_posts = @trip.discussion_posts.includes(:user, :discussion_replies)
                             .recent
    @new_discussion_post = DiscussionPost.new
  end

  def show
    @top_level_replies = @discussion_post.discussion_replies.includes(:user, :children => :user).top_level.oldest_first
    @new_reply = DiscussionReply.new
  end

  def new
    @discussion_post = @trip.discussion_posts.build
  end

  def create
    @discussion_post = @trip.discussion_posts.build(discussion_post_params)
    @discussion_post.user = Current.user

    if @discussion_post.save
      redirect_to trip_discussion_path(@trip, @discussion_post), notice: t('discussions.created')
    else
      @discussion_posts = @trip.discussion_posts.includes(:user, :discussion_replies).recent
      @new_discussion_post = @discussion_post
      render :index, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @discussion_post.update(discussion_post_params)
      redirect_to trip_discussion_path(@trip, @discussion_post), notice: t('discussions.updated')
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @discussion_post.destroy
    redirect_to trip_discussions_path(@trip), notice: t('discussions.deleted')
  end

  def upvote
    vote_for_post('upvote')
  end

  def downvote
    vote_for_post('downvote')
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def set_discussion_post
    @discussion_post = @trip.discussion_posts.find(params[:id])
  end

  def verify_trip_access
    redirect_to trips_path unless @trip.has_member?(Current.user)
  end

  def verify_post_ownership
    redirect_to trip_discussions_path(@trip) unless @discussion_post.user == Current.user
  end

  def discussion_post_params
    params.require(:discussion_post).permit(:title, :content)
  end
  
  def vote_for_post(vote_type)
    existing_vote = @discussion_post.discussion_votes.find_by(user: Current.user)
    
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
      @discussion_post.discussion_votes.create!(user: Current.user, vote_type: vote_type)
    end
    
    redirect_back(fallback_location: trip_discussion_path(@trip, @discussion_post))
  end
end