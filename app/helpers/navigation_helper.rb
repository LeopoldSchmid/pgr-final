module NavigationHelper
  # Returns CSS class for active navigation items
  def active_nav_class(section)
    return "" unless section.present?

    case section.to_sym
    when :home
      current_page?(root_path) ? "text-primary-accent font-semibold" : "text-text-primary/70"
    when :trip
      (controller_name == "trips" && %w[show overview details dates participants discussions].include?(action_name)) ? "text-primary-accent font-semibold" : "text-text-primary/70"
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
        # Use new trip overview page
        trip_overview_path
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

  # Get secondary navigation icon for each item key
  def secondary_nav_icon_for(item_key)
    icons = {
      # Plans section
      meals: "M12 8v13m0-13V6a2 2 0 112 2h-2zm0 0V5.5A2.5 2.5 0 109.5 8H12zm-7 4h14M5 12a2 2 0 110-4h14a2 2 0 110 4M5 12v7a2 2 0 002 2h10a2 2 0 002-2v-7",
      shopping: "M3 3h2l.4 2M7 13h10l4-8H5.4M7 13L5.4 5M7 13l-2.293 2.293c-.63.63-.184 1.707.707 1.707H17m0 0a2 2 0 100 4 2 2 0 000-4zm-8 2a2 2 0 11-4 0 2 2 0 014 0z",
      packing: "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4",
      itinerary: "M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-3 7h3m-3 4h3m-6-4h.01M9 16h.01",
      recipes: "M12 6.253v13m0-13C10.832 5.477 9.246 5 7.5 5S4.168 5.477 3 6.253v13C4.168 18.477 5.754 18 7.5 18s3.332.477 4.5 1.253m0-13C13.168 5.477 14.754 5 16.5 5c1.747 0 3.332.477 4.5 1.253v13C19.832 18.477 18.247 18 16.5 18c-1.746 0-3.332.477-4.5 1.253",
      templates: "M4 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H5a1 1 0 01-1-1v-4zM14 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z",

      # Trip section
      overview: "M4 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1H5a1 1 0 01-1-1V5zM14 5a1 1 0 011-1h4a1 1 0 011 1v7a1 1 0 01-1 1h-4a1 1 0 01-1-1V5zM4 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1H5a1 1 0 01-1-1v-4zM14 15a1 1 0 011-1h4a1 1 0 011 1v4a1 1 0 01-1 1h-4a1 1 0 01-1-1v-4z",
      details: "M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z",
      participants: "M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z",
      discussions: "M17 8h2a2 2 0 012 2v6a2 2 0 01-2 2h-2v4l-4-4H9a1.994 1.994 0 01-1.414-.586m0 0L11 14h4a2 2 0 002-2V6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2v4l.586-.586z",
      dates: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",

      # Memories section
      feed: "M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10",
      albums: "M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z",
      map: "M9 20l-5.447-2.724A1 1 0 013 16.382V5.618a1 1 0 011.447-.894L9 7m0 13l6-3m-6 3V7m6 10l4.553 2.276A1 1 0 0021 18.382V7.618a1 1 0 00-.553-.894L15 4m0 13V4m0 0L9 7",
      favorites: "M11.049 2.927c.3-.921 1.603-.921 1.902 0l1.519 4.674a1 1 0 00.95.69h4.915c.969 0 1.371 1.24.588 1.81l-3.976 2.888a1 1 0 00-.363 1.118l1.518 4.674c.3.922-.755 1.688-1.538 1.118l-3.976-2.888a1 1 0 00-1.176 0l-3.976 2.888c-.783.57-1.838-.197-1.538-1.118l1.518-4.674a1 1 0 00-.363-1.118l-3.976-2.888c-.784-.57-.38-1.81.588-1.81h4.914a1 1 0 00.951-.69l1.519-4.674z",

      # Expenses section
      all: "M4 6h16M4 10h16M4 14h16M4 18h16",
      by_person: "M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z",
      by_category: "M7 7h.01M7 3h5c.512 0 1.024.195 1.414.586l7 7a2 2 0 010 2.828l-7 7a2 2 0 01-2.828 0l-7-7A1.994 1.994 0 013 12V7a4 4 0 014-4z",
      settle: "M9 8h6m-5 0a3 3 0 110 6H9l3 3m-3-6h6m6 1a9 9 0 11-18 0 9 9 0 0118 0z",
      all_trips: "M3.055 11H5a2 2 0 012 2v1a2 2 0 002 2 2 2 0 012 2v2.945M8 3.935V5.5A2.5 2.5 0 0010.5 8h.5a2 2 0 012 2 2 2 0 104 0 2 2 0 012-2h1.064M15 20.488V18a2 2 0 012-2h3.064M21 12a9 9 0 11-18 0 9 9 0 0118 0z",
      summary: "M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z",

      # Home section
      calendar: "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z",
      upcoming: "M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z"
    }

    icons[item_key.to_sym]
  end

  # Get pending invitations count for badge
  def pending_invitations_count
    return 0 unless authenticated?
    Invitation.where(email: Current.user.email_address).pending.count
  end

  # ============================================================
  # Secondary Navigation Methods
  # ============================================================

  # Determine if secondary nav should be shown for this section
  def show_secondary_navigation?(section)
    return false unless section.present?

    case section.to_sym
    when :plans, :memories, :expenses, :trip, :home
      true
    else
      false
    end
  end

  # Get secondary nav items for a section
  def secondary_nav_items(section)
    return [] unless section.present?

    case section.to_sym
    when :plans
      if current_trip
        [
          { key: :meals, label: t('navigation.secondary.meals'), path: plans_meals_path },
          { key: :shopping, label: t('navigation.secondary.shopping'), path: plans_shopping_path },
          { key: :packing, label: t('navigation.secondary.packing'), path: plans_packing_path },
          { key: :itinerary, label: t('navigation.secondary.itinerary'), path: plans_itinerary_path }
        ]
      else
        [
          { key: :recipes, label: t('navigation.secondary.recipes'), path: recipe_library_path },
          { key: :templates, label: t('navigation.secondary.templates'), path: plans_templates_path }
        ]
      end
    when :trip
      return [] unless current_trip
      [
        { key: :overview, label: t('navigation.secondary.overview'), path: trip_overview_path },
        { key: :dates, label: t('navigation.secondary.dates'), path: trip_dates_path },
        { key: :details, label: t('navigation.secondary.details'), path: trip_details_path },
        { key: :participants, label: t('navigation.secondary.participants'), path: trip_participants_path },
        { key: :discussions, label: t('navigation.secondary.discussions'), path: trip_discussions_path }
      ]
    when :memories
      if current_trip
        [
          { key: :feed, label: t('navigation.secondary.feed'), path: memories_path },
          { key: :albums, label: t('navigation.secondary.albums'), path: memories_albums_path },
          { key: :map, label: t('navigation.secondary.map'), path: memories_map_path }
        ]
      else
        [
          { key: :feed, label: t('navigation.secondary.feed'), path: memories_path },
          { key: :favorites, label: t('navigation.secondary.favorites'), path: memories_favorites_path }
        ]
      end
    when :expenses
      if current_trip
        [
          { key: :all, label: t('navigation.secondary.all'), path: expenses_path },
          { key: :by_person, label: t('navigation.secondary.by_person'), path: expenses_by_person_path },
          { key: :by_category, label: t('navigation.secondary.by_category'), path: expenses_by_category_path },
          { key: :settle, label: t('navigation.secondary.settle'), path: expenses_settle_path }
        ]
      else
        [
          { key: :all_trips, label: t('navigation.secondary.all_trips'), path: expenses_path },
          { key: :summary, label: t('navigation.secondary.summary'), path: expenses_summary_path }
        ]
      end
    when :home
      [
        { key: :overview, label: t('navigation.secondary.overview'), path: root_path },
        { key: :calendar, label: t('navigation.secondary.calendar'), path: home_calendar_path },
        { key: :upcoming, label: t('navigation.secondary.upcoming'), path: home_upcoming_path }
      ]
    else
      []
    end
  end

  # Check if a secondary nav item is active
  def secondary_nav_active?(section, item_key)
    return false unless section.present? && item_key.present?

    case section.to_sym
    when :plans
      controller_name == 'plans' && action_name == item_key.to_s ||
      controller_name == 'recipe_library' && item_key == :recipes
    when :trip
      (controller_name == 'trips' && action_name == item_key.to_s) ||
      (controller_name == 'discussions' && item_key == :discussions) ||
      (controller_name == 'date_proposals' && item_key == :dates)
    when :memories
      controller_name == 'memories' && (action_name == item_key.to_s || (item_key == :feed && action_name == 'index'))
    when :expenses
      controller_name == 'expenses' && (action_name == item_key.to_s || (item_key == :all && action_name == 'index'))
    when :home
      (controller_name == 'home' && action_name == item_key.to_s) ||
      (item_key == :overview && current_page?(root_path))
    else
      false
    end
  end

  # Determine which section we're currently in (for rendering secondary nav)
  def current_navigation_section
    case controller_name
    when 'plans', 'recipe_library', 'shopping_lists', 'recipes'
      :plans
    when 'trips'
      :trip
    when 'memories'
      :memories
    when 'expenses'
      :expenses
    when 'home'
      :home
    else
      nil
    end
  end
end
