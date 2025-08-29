class HomeController < ApplicationController
  def index
    if authenticated?
      # Show dashboard for logged-in users
      @current_user = Current.user
    else
      # Show landing page for guests
    end
  end
end