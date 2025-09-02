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

  def compact_time_ago(time)
    return '' unless time.present?
    
    now = Time.current
    diff = now - time
    
    if time.to_date == now.to_date
      # Same day - show time (HH:MM)
      time.strftime("%H:%M")
    elsif diff < 1.week
      # Less than a week - show days (e.g., "3d")
      "#{diff.to_i / 1.day}d"
    elsif diff < 1.month
      # Less than a month - show weeks (e.g., "2w")
      "#{diff.to_i / 1.week}w"
    elsif diff < 1.year
      # Less than a year - show months (e.g., "3m")
      "#{diff.to_i / 1.month}m"
    else
      # More than a year - show years (e.g., "2y")
      "#{diff.to_i / 1.year}y"
    end
  end

  def user_avatar(user, size: 8)
    size_class = case size
                 when 5 then "w-5 h-5 text-xs"
                 when 6 then "w-6 h-6 text-xs"
                 when 8 then "w-8 h-8 text-sm"
                 else "w-8 h-8 text-sm"
                 end
    
    content_tag :div, class: "flex-shrink-0" do
      content_tag :div, 
        user.email_address.first.upcase,
        class: "#{size_class} bg-primary-accent text-white rounded-full flex items-center justify-center font-medium"
    end
  end
  
  def vote_button_class(votable, vote_type, current_user)
    user_vote = votable.user_vote(current_user)
    base_class = "p-1"
    
    if user_vote == vote_type
      # User has voted this way - show active state
      vote_type == 'upvote' ? "vote-upvote-active #{base_class}" : "vote-downvote-active #{base_class}"
    else
      # User hasn't voted this way - show default state
      vote_type == 'upvote' ? "vote-upvote #{base_class}" : "vote-downvote #{base_class}"
    end
  end
  
end
