class InvitationMailer < ApplicationMailer
  def invitation_email(invitation, accept_url, decline_url)
    @invitation = invitation
    @accept_url = accept_url
    @decline_url = decline_url
    @invited_by = @invitation.invited_by
    @trip = @invitation.trip

    mail(to: @invitation.email, subject: "You're invited to PlanGoReminisce: #{@trip.name}!")
  end
end
