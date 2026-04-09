class PlansController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context, except: [:index, :templates]

  def index
    # Smart redirect based on context
    if current_trip
      redirect_to plans_meals_path
    else
      redirect_to recipe_library_path
    end
  end

  # Trip context: Meals planning
  def meals
    @trip = current_trip
    @recipes = @trip.recipes.order(:name)
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    @end_date = @start_date.end_of_week
    @meal_plans = @trip.meal_plans.includes(:recipe).ordered
    @planned_meals = @meal_plans.group_by(&:date).transform_values { |plans| plans.group_by(&:meal_type) }
  end

  # Trip context: Shopping lists
  def shopping
    @trip = current_trip
    @shopping_lists = @trip.shopping_lists.includes(:shopping_items).order(created_at: :desc)
  end

  # Trip context: Packing list
  def packing
    @trip = current_trip
    # Packing list functionality to be implemented
    @packing_items = [] # Placeholder
  end

  # Trip context: Itinerary
  def itinerary
    @trip = current_trip
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
    unless current_trip
      flash[:alert] = t('plans.errors.no_trip_selected')
      redirect_to select_trip_path(return_to: plans_path)
    end
  end
end
