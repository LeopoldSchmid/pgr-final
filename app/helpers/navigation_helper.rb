module NavigationHelper
  # Returns CSS class for active navigation items
  def active_nav_class(section)
    return "" unless section.present?

    case section.to_sym
    when :home
      current_page?(root_path) ? "text-primary-accent font-semibold" : "text-text-primary/70"
    when :trip
      (controller_name == "trips" && action_name == "show") ? "text-primary-accent font-semibold" : "text-text-primary/70"
    when :plans
      controller_name == "plans" ? "text-primary-accent font-semibold" : "text-text-primary/70"
    when :memories
      controller_name == "memories" ? "text-primary-accent font-semibold" : "text-text-primary/70"
    when :expenses
      controller_name == "expenses" ? "text-primary-accent font-semibold" : "text-text-primary/70"
    else
      "text-text-primary/70"
    end
  end

  # Returns display text for trip context in top bar
  def trip_context_display
    if current_trip
      current_trip.name
    else
      t('app_name')
    end
  end

  # Smart path generation for features based on trip context
  def scoped_feature_path(feature)
    case feature.to_sym
    when :home
      root_path
    when :trip
      if current_trip
        # Use context-based trip hub page based on current phase
        case current_trip.current_phase
        when 'plan'
          trip_plan_context_path
        when 'go'
          trip_go_context_path
        when 'reminisce'
          trip_reminisce_context_path
        else
          trip_plan_context_path
        end
      elsif current_trip_or_next
        trip_path(current_trip_or_next)
      else
        new_trip_path
      end
    when :plans
      if current_trip
        plans_path
      else
        select_trip_path(return_to: plans_path)
      end
    when :memories
      if current_trip
        memories_path
      else
        select_trip_path(return_to: memories_path)
      end
    when :expenses
      if current_trip
        expenses_path
      else
        select_trip_path(return_to: expenses_path)
      end
    else
      root_path
    end
  end

  # Check if user should see back button
  def show_back_button?
    # Show back button if not on home page
    !current_page?(root_path) && authenticated?
  end

  # Get appropriate back path
  def back_path
    if current_trip
      trip_path(current_trip)
    else
      root_path
    end
  end

  # Determine which navigation icon to show for each section
  def nav_icon_for(section)
    icons = {
      home: "M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6",
      trip: "M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7",
      plans: "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01",
      memories: "M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z",
      memories_circle: "M15 13a3 3 0 11-6 0 3 3 0 016 0z",
      expenses: "M17 9V7a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2m2 4h10a2 2 0 002-2v-6a2 2 0 00-2-2H9a2 2 0 00-2 2v6a2 2 0 002 2zm7-5a2 2 0 11-4 0 2 2 0 014 0z"
    }

    icons[section.to_sym]
  end

  # Get pending invitations count for badge
  def pending_invitations_count
    return 0 unless authenticated?
    Invitation.where(email: Current.user.email_address).pending.count
  end
end
