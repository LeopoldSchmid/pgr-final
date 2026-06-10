class PlansController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context, except: [ :index, :templates ]
  before_action :store_last_plans_tab, only: [ :meals, :packing, :itinerary ]

  def index
    # Smart redirect based on context
    if resolved_trip.present?
      redirect_to last_plans_tab_path(resolved_trip)
    else
      redirect_to recipe_library_path
    end
  end

  # Trip context: Meals planning
  def meals
    @trip = resolved_trip
    @recipes = accessible_recipes
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    @end_date = @start_date.end_of_week
    @selected_date = params[:selected_date] ? Date.parse(params[:selected_date]) : @start_date
    @selected_date = @selected_date.clamp(@start_date, @end_date)
    @meal_types = MealPlan::MEAL_TYPES
    @trip_users = @trip.trip_members.active_members.includes(:user).map(&:user)
    @meal_plans = @trip.meal_plans.includes(:recipe).ordered
    @planned_meals = @meal_plans.group_by(&:date).transform_values { |plans| plans.group_by(&:meal_type) }
    @day_meals = @planned_meals[@selected_date] || {}
  end

  # Trip context: Shopping lists
  def shopping
    @trip = resolved_trip
    @shopping_list = ShoppingList.current_for_trip(@trip)
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id)
  end

  # Trip context: Packing list
  def packing
    @trip = resolved_trip
    # Packing list functionality to be implemented
    @packing_items = [] # Placeholder
  end

  # Trip context: Itinerary
  def itinerary
    @trip = resolved_trip
    # Itinerary functionality to be implemented
    @itinerary_items = [] # Placeholder
  end

  # Global context: Templates
  def templates
    # Template functionality to be implemented
    @templates = [] # Placeholder
  end

  private

  def ensure_trip_context
    unless resolved_trip
      flash[:alert] = t("plans.errors.no_trip_selected")
      redirect_to select_trip_path(return_to: plans_path)
    end
  end

  def resolved_trip
    return current_trip if current_trip.present?
    return nil if params[:trip_id].blank?

    user = Current.session&.user || Current.user
    return nil unless user

    trip = user.trips.find_by(id: params[:trip_id])
    trip ||= Trip.joins(:trip_members).where(trip_members: { user: user }, id: params[:trip_id]).first
    trip
  end

  def store_last_plans_tab
    session[:last_plans_tab] = action_name
  end

  def last_plans_tab_path(trip)
    case session[:last_plans_tab]
    when "shopping_plan"
      plans_shopping_path(trip_id: trip.id)
    when "shopping_list"
      plans_shopping_list_path(trip_id: trip.id)
    when "packing"
      plans_packing_path(trip_id: trip.id)
    when "itinerary"
      plans_itinerary_path(trip_id: trip.id)
    else
      plans_meals_path(trip_id: trip.id)
    end
  end

  def accessible_recipes
    trip_ids = (Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)).uniq

    Recipe.where(
      "source_type = 'public' OR (source_type = 'personal' AND user_id = ?) OR (source_type = 'trip' AND trip_id IN (?))",
      Current.user.id,
      trip_ids.presence || [0]
    ).order(:name)
  end
end
