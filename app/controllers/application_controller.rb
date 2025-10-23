class ApplicationController < ActionController::Base
  include Authentication
  include TripContext
  
  helper_method :current_trip, :current_trip_or_next
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern
  
  before_action :set_locale
  
  private
  
  def set_locale
    I18n.locale = current_locale
  end
  
  def current_locale
    # 1. Check URL parameter (for explicit switching)
    if params[:locale].present? && I18n.available_locales.include?(params[:locale].to_sym)
      session[:locale] = params[:locale]
      return params[:locale].to_sym
    end
    
    # 2. Check session (user previously switched)
    if session[:locale].present? && I18n.available_locales.include?(session[:locale].to_sym)
      return session[:locale].to_sym
    end
    
    # 3. Check user preference (if authenticated)
    if authenticated? && Current.user.locale.present?
      return Current.user.preferred_locale
    end
    
    # 4. Check browser locale
    browser_locale = extract_locale_from_accept_language_header
    if browser_locale && I18n.available_locales.include?(browser_locale)
      return browser_locale
    end
    
    # 5. Fall back to default locale
    I18n.default_locale
  end
  
  def extract_locale_from_accept_language_header
    return nil unless request.env['HTTP_ACCEPT_LANGUAGE']
    
    request.env['HTTP_ACCEPT_LANGUAGE'].scan(/^[a-z]{2}/).first&.to_sym
  end
  
  # Helper to generate locale-aware URLs
  def default_url_options
    { locale: I18n.locale }
  end
end
