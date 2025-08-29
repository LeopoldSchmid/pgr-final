class RegistrationsController < ApplicationController
  def show
    redirect_to root_path if authenticated?
  end

  def new
    redirect_to root_path if authenticated?
  end

  def create
    @user = User.new(registration_params)
    
    if @user.save
      session_record = @user.sessions.create!(
        user_agent: request.user_agent,
        ip_address: request.remote_ip
      )
      cookies.signed.permanent[:session_token] = { value: session_record.id, httponly: true }
      
      redirect_to root_path, notice: "Welcome! Your account was created successfully."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def registration_params
    params.require(:user).permit(:email_address, :password, :password_confirmation)
  end
end