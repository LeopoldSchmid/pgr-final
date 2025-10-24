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
      (controller_name == 'discussions' && item_key == :discussions)
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
