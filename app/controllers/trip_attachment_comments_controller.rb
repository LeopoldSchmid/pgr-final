class TripAttachmentCommentsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :authorize_member
  before_action :set_trip_attachment

  def create
    @comment = @trip_attachment.trip_attachment_comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to plan_trip_path(@trip), notice: 'Comment added!'
    else
      redirect_to plan_trip_path(@trip), alert: 'Could not add comment.'
    end
  end

  def destroy
    @comment = @trip_attachment.trip_attachment_comments.find(params[:id])
    
    # Only allow deletion by comment author or trip owner
    if @comment.user == Current.user || @trip.user == Current.user
      @comment.destroy
      redirect_to plan_trip_path(@trip), notice: 'Comment deleted!'
    else
      redirect_to plan_trip_path(@trip), alert: 'You can only delete your own comments.'
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

  def set_trip_attachment
    @trip_attachment = @trip.trip_attachments.find(params[:trip_attachment_id])
  end

  def comment_params
    params.require(:trip_attachment_comment).permit(:content)
  end
end