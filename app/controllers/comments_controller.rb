class CommentsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_journal_entry

  def create
    @comment = @journal_entry.comments.build(comment_params)
    @comment.user = Current.user

    if @comment.save
      redirect_to journal_trip_path(@trip), notice: 'Comment added!'
    else
      redirect_to journal_trip_path(@trip), alert: 'Could not add comment.'
    end
  end

  def destroy
    @comment = @journal_entry.comments.find(params[:id])
    @comment.destroy
    redirect_to journal_trip_path(@trip), notice: 'Comment deleted!'
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:trip_id])
  end

  def set_journal_entry
    @journal_entry = @trip.journal_entries.find(params[:journal_entry_id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end