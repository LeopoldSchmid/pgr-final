class TripAttachmentsController < ApplicationController
  before_action :set_trip
  before_action :authorize_member

  def create
    @trip_attachment = @trip.trip_attachments.build(attachment_params)
    @trip_attachment.user = current_user

    if @trip_attachment.save
      redirect_to @trip, notice: 'Attachment was successfully uploaded.'
    else
      redirect_to @trip, alert: "Failed to upload attachment: #{@trip_attachment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @trip_attachment = @trip.trip_attachments.find(params[:id])
    @trip_attachment.destroy
    redirect_to @trip, notice: 'Attachment was successfully deleted.'
  end

  private

  def set_trip
    @trip = Trip.find(params[:trip_id])
  end

  def authorize_member
    unless @trip.has_member?(current_user)
      redirect_to root_path, alert: 'You are not a member of this trip.'
    end
  end

  def attachment_params
    params.require(:trip_attachment).permit(:name, :file)
  end
end
