module ApplicationHelper
  include ActionView::Helpers::TextHelper

  def format_journal_content(content)
    return "" if content.blank?

    # First apply simple_format for line breaks and paragraphs
    formatted_content = simple_format(content)

    # Then auto-link URLs using a custom implementation
    auto_link_urls(formatted_content)
  end

  private

  def auto_link_urls(text)
    return text unless text.present?
    
    # Simple URL regex pattern - more conservative
    url_pattern = /(https?:\/\/[^\s<>"]+)/i

    text.gsub(url_pattern) do |url|
      %(<a href="#{url}" target="_blank" rel="noopener noreferrer" class="text-primary-accent hover:underline">#{url}</a>)
    end.html_safe
  end

  # Navigation context helpers
  def current_trip_context
    # First check session for persisted trip context
    if session[:current_trip_id]
      trip = begin
        Current.user.trips.find_by(id: session[:current_trip_id])
      rescue ActiveRecord::RecordNotFound, NoMethodError
        nil
      end

      # Also check if user is a member
      trip ||= Trip.joins(:trip_members)
                   .where(trip_members: { user: Current.user }, id: session[:current_trip_id])
                   .first rescue nil

      return trip if trip
    end

    # Fall back to URL params for trip context
    return nil unless params[:controller] == "trips" || params[:trip_id].present?

    trip_id = params[:trip_id] || (params[:controller] == "trips" ? params[:id] : nil)
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
    return "" unless time.present?

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
    when 20 then "w-20 h-20 text-2xl"
    else "w-8 h-8 text-sm"
    end

    content_tag :div, class: "flex-shrink-0" do
      if user.avatar.present? && avatar_options.key?(user.avatar.to_sym)
        avatar_config = avatar_options[user.avatar.to_sym]
        content_tag :div,
          avatar_config[:icon],
          class: "#{size_class} #{avatar_config[:bg_color]} text-white rounded-full flex items-center justify-center font-medium"
      else
        # Fallback to initial
        content_tag :div,
          user.email_address.first.upcase,
          class: "#{size_class} bg-primary-accent text-white rounded-full flex items-center justify-center font-medium"
      end
    end
  end

  def avatar_options
    {
      traveler: { icon: "✈️", bg_color: "bg-blue-500", name: "Traveler" },
      adventurer: { icon: "🏔️", bg_color: "bg-green-600", name: "Adventurer" },
      photographer: { icon: "📷", bg_color: "bg-purple-500", name: "Photographer" },
      foodie: { icon: "🍽️", bg_color: "bg-orange-500", name: "Foodie" },
      explorer: { icon: "🧭", bg_color: "bg-teal-500", name: "Explorer" },
      beachgoer: { icon: "🏖️", bg_color: "bg-cyan-500", name: "Beach Lover" },
      hiker: { icon: "🥾", bg_color: "bg-amber-600", name: "Hiker" },
      cultural: { icon: "🏛️", bg_color: "bg-indigo-500", name: "Culture Enthusiast" },
      nature: { icon: "🌿", bg_color: "bg-emerald-600", name: "Nature Lover" },
      wanderer: { icon: "🎒", bg_color: "bg-rose-500", name: "Wanderer" }
    }
  end

  def vote_button_class(votable, vote_type, current_user)
    user_vote = votable.user_vote(current_user)
    base_class = "p-1"

    if user_vote == vote_type
      # User has voted this way - show active state
      vote_type == "upvote" ? "vote-upvote-active #{base_class}" : "vote-downvote-active #{base_class}"
    else
      # User hasn't voted this way - show default state
      vote_type == "upvote" ? "vote-upvote #{base_class}" : "vote-downvote #{base_class}"
    end
  end
end
