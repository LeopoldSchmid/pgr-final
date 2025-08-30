class InvitationsController < ApplicationController
  allow_unauthenticated_access only: [:show, :accept, :decline]
  before_action :set_trip, only: [:new, :create, :destroy], if: -> { params[:trip_id] }
  before_action :set_trip_for_index, only: [:index]
  before_action :set_invitation_by_token, only: [:show, :accept, :decline]
  before_action :set_invitation_by_id, only: [:destroy]
  before_action :authorize_trip_access, only: [:new, :create, :destroy], if: -> { @trip }

  def index
    if @trip
      # Trip-specific invitations (for trip management)
      @pending_invitations = @trip.invitations.pending.includes(:invited_by)
      @accepted_invitations = @trip.invitations.accepted.includes(:invited_by)
      render :trip_invitations_index
    else
      # User's personal invitation inbox
      @pending_invitations = Invitation.where(email: Current.user.email_address).pending.includes(:trip, :invited_by)
      render :user_invitations_index
    end
  end

  def new
    @invitation = @trip.invitations.build
  end

  def create
    @invitation = @trip.invitations.build(invitation_params)
    @invitation.invited_by = Current.user

    if @invitation.save
      # TODO: Send invitation email
      redirect_to trip_invitations_path(@trip), 
                  notice: "💌 Invitation sent to #{@invitation.email}!"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    if @invitation.expired?
      render :expired
      return
    elsif !@invitation.pending?
      render :already_responded
      return
    end
    
    # If user is not signed in and invitation is valid, redirect to streamlined registration
    if !Current.user && @invitation.can_be_accepted?
      # Check if user already exists
      existing_user = User.find_by(email_address: @invitation.email)
      if existing_user
        # User exists but not signed in - redirect to sign in
        session[:invitation_token] = @invitation.token
        redirect_to new_session_path, 
                    notice: "Please sign in with #{@invitation.email} to accept the invitation"
      else
        # User doesn't exist - redirect to streamlined registration
        session[:invitation_token] = @invitation.token
        redirect_to new_registration_path(email: @invitation.email), 
                    notice: "Create your account to join #{@invitation.trip.name}!"
      end
      return
    end
    
    # User is signed in - show the invitation
  end

  def accept
    if Current.user
      # User is already signed in
      if @invitation.accept!(Current.user)
        redirect_to trip_path(@invitation.trip), 
                    notice: "🎉 Welcome to #{@invitation.trip.name}!"
      else
        redirect_to invitation_path(@invitation.token), 
                    alert: "Unable to accept invitation. It may have expired."
      end
    else
      # User needs to sign in or register first
      session[:invitation_token] = @invitation.token
      redirect_to new_registration_path, 
                  notice: "Please create an account to join #{@invitation.trip.name}"
    end
  end

  def decline
    if @invitation.decline!
      render :declined
    else
      redirect_to invitation_path(@invitation.token), 
                  alert: "Unable to decline invitation."
    end
  end

  def destroy
    @invitation = @trip.invitations.find(params[:id])
    @invitation.destroy
    redirect_to trip_invitations_path(@trip), 
                notice: "💥 Invitation cancelled successfully!"
  end

  private

  def set_trip
    @trip = Current.user.trips.find(params[:trip_id])
  end
  
  def set_trip_for_index
    @trip = Current.user.trips.find(params[:trip_id]) if params[:trip_id]
  end

  def set_invitation_by_token
    @invitation = Invitation.find_by!(token: params[:token])
  rescue ActiveRecord::RecordNotFound
    render :not_found, status: :not_found
  end
  
  def set_invitation_by_id
    @invitation = @trip.invitations.find(params[:id])
  end

  def authorize_trip_access
    unless @trip.user_can_manage_expenses?(Current.user)
      redirect_to @trip, alert: "You don't have permission to manage invitations for this trip."
    end
  end

  def invitation_params
    params.require(:invitation).permit(:email, :role)
  end
  
  def redirect_to_sign_in_with_invitation
    session[:invitation_token] = @invitation.token
    redirect_to new_session_path, 
                notice: "Please sign in to accept the invitation to #{@invitation.trip.name}"
  end
end
