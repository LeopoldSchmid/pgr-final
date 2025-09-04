class TripAttachmentsController < ApplicationController
  before_action :set_trip
  before_action :authorize_member

  def create
    Rails.logger.debug "=== TripAttachmentsController#create called ==="
    Rails.logger.debug "Params: #{params.inspect}"
    Rails.logger.debug "Trip: #{@trip.name}"
    Rails.logger.debug "User: #{Current.user.email_address}"
    
    @trip_attachment = @trip.trip_attachments.build(attachment_params)
    @trip_attachment.user = Current.user

    Rails.logger.debug "Attachment created: #{@trip_attachment.inspect}"
    Rails.logger.debug "Attachment valid?: #{@trip_attachment.valid?}"
    Rails.logger.debug "Attachment errors: #{@trip_attachment.errors.full_messages}"

    if @trip_attachment.save
      redirect_to plan_trip_path(@trip), notice: 'Attachment was successfully uploaded.'
    else
      Rails.logger.error "Failed to save attachment: #{@trip_attachment.errors.full_messages}"
      redirect_to plan_trip_path(@trip), alert: "Failed to upload attachment: #{@trip_attachment.errors.full_messages.join(', ')}"
    end
  end

  def update
    @trip_attachment = @trip.trip_attachments.find(params[:id])
    
    if @trip_attachment.update(attachment_update_params)
      redirect_to plan_trip_path(@trip), notice: 'Attachment name was successfully updated.'
    else
      redirect_to plan_trip_path(@trip), alert: "Failed to update attachment: #{@trip_attachment.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @trip_attachment = @trip.trip_attachments.find(params[:id])
    @trip_attachment.destroy
    redirect_to plan_trip_path(@trip), notice: 'Attachment was successfully deleted.'
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

  def attachment_params
    params.require(:trip_attachment).permit(:name, files: [])
  end

  def attachment_update_params
    params.require(:trip_attachment).permit(:name)
  end
end
