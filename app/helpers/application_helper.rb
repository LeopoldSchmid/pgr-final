module ApplicationHelper
  include ActionView::Helpers::TextHelper

  def format_journal_content(content)
    return '' if content.blank?
    
    # First apply simple_format for line breaks and paragraphs
    formatted_content = simple_format(content)
    
    # Then auto-link URLs
    auto_link(formatted_content)
  end

  # Navigation context helpers
  def current_trip_context
    # Only look for trip context in trip-related routes
    return nil unless params[:controller] == 'trips' || params[:trip_id].present?
    
    trip_id = params[:trip_id] || (params[:controller] == 'trips' ? params[:id] : nil)
    return nil unless trip_id
    
    # Find the trip if user has access
    begin
      Current.user.trips.find(trip_id)
    rescue ActiveRecord::RecordNotFound
      # Check if user is a member
      Trip.joins(:trip_members)
          .where(trip_members: { user: Current.user }, id: trip_id)
          .first
    rescue ActiveRecord::StatementInvalid
      # Handle case where trip_id is not a valid integer
      nil
    end
  end

  def in_trip_context?
    current_trip_context.present?
  end

  def context_aware_navigation_path(phase)
    if in_trip_context?
      # Trip-specific phase path
      send("#{phase}_trip_path", current_trip_context)
    else
      # Global phase path
      "/#{phase}"
    end
  end

  def navigation_context_indicator
    if in_trip_context?
      content_tag :div, class: "bg-primary-accent/10 border border-primary-accent/20 rounded-lg px-3 py-1 mb-4" do
        content_tag :span, class: "text-sm font-medium text-primary-accent flex items-center" do
          concat content_tag(:span, "📍", class: "mr-2")
          concat "In: #{current_trip_context.name}"
        end
      end
    end
  end

  
end
