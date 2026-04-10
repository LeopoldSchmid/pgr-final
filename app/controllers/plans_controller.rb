class PlansController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context, except: [ :index, :templates ]

  def index
    # Smart redirect based on context
    if resolved_trip.present?
      redirect_to plans_meals_path(trip_id: resolved_trip.id)
    else
      redirect_to recipe_library_path
    end
  end

  # Trip context: Meals planning
  def meals
    @trip = resolved_trip
    @recipes = @trip.recipes.order(:name)
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    @end_date = @start_date.end_of_week
    @meal_plans = @trip.meal_plans.includes(:recipe).ordered
    @planned_meals = @meal_plans.group_by(&:date).transform_values { |plans| plans.group_by(&:meal_type) }
  end

  # Trip context: Shopping lists
  def shopping
    @trip = resolved_trip
    @shopping_list = ShoppingList.current_for_trip(@trip)
    redirect_to trip_shopping_list_path(@trip, @shopping_list)
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
end
