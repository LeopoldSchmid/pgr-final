class RegistrationsController < ApplicationController
  allow_unauthenticated_access
  
  def show
    redirect_to root_path if authenticated?
  end

  def new
    if authenticated?
      redirect_to root_path
      return
    end
    
    @user = User.new(email_address: params[:email])
    @invitation_token = session[:invitation_token]
    @invitation = Invitation.find_by(token: @invitation_token) if @invitation_token
    
    # Debug logging
    Rails.logger.info "Registration NEW: email param = #{params[:email]}, invitation_token = #{@invitation_token}"
  end

  def create
    Rails.logger.info "Registration CREATE: params = #{params.inspect}"
    @user = User.new(registration_params)
    Rails.logger.info "User object: #{@user.attributes}"
    
    # Check if user already exists (in case of double-submission)
    existing_user = User.find_by(email_address: @user.email_address)
    if existing_user
      # User already exists, just sign them in
      start_new_session_for(existing_user)
      
      # Handle invitation acceptance if there's a pending invitation
      if session[:invitation_token]
        invitation = Invitation.find_by(token: session[:invitation_token])
        if invitation&.can_be_accepted?
          invitation.accept!(existing_user)
          session.delete(:invitation_token)
          redirect_to invitation.trip, notice: "🎉 Welcome back! You've joined #{invitation.trip.name}!"
          return
        end
      end
      
      redirect_to root_path, notice: "Welcome back! You're already signed in."
      return
    end
    
    if @user.save
      # Use the standard authentication method to create session
      start_new_session_for(@user)
      
      # Handle invitation acceptance if there's a pending invitation
      if session[:invitation_token]
        invitation = Invitation.find_by(token: session[:invitation_token])
        if invitation&.can_be_accepted?
          invitation.accept!(@user)
          session.delete(:invitation_token)
          redirect_to invitation.trip, notice: "🎉 Welcome! Your account was created and you've joined #{invitation.trip.name}!"
          return
        end
      end
      
      redirect_to root_path, notice: "Welcome! Your account was created successfully."
    else
      # Re-populate form data for errors
      @invitation_token = session[:invitation_token]
      @invitation = Invitation.find_by(token: @invitation_token) if @invitation_token
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end