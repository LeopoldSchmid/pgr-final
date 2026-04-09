class MealPlansController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_meal_plan, only: [:update, :destroy]

  def index
    @meal_plans = @trip.meal_plans.includes(:recipe).ordered
    @recipes = @trip.recipes.order(:name)
    
    # Default to current week or trip start date
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    @end_date = @start_date.end_of_week
    
    @planned_meals = @meal_plans.group_by(&:date).transform_values { |plans| plans.group_by(&:meal_type) }
  end

  def create
    @meal_plan = @trip.meal_plans.build(meal_plan_params)

    if @meal_plan.save
      redirect_to plans_meals_path(start_date: @meal_plan.date.beginning_of_week), notice: 'Meal scheduled successfully.'
    else
      redirect_to plans_meals_path, alert: 'Could not schedule meal.'
    end
  end

  def update
    if @meal_plan.update(meal_plan_params)
      respond_to do |format|
        format.html { redirect_to plans_meals_path(start_date: @meal_plan.date.beginning_of_week), notice: 'Meal plan updated.' }
        format.json { render json: { status: 'success' } }
      end
    else
      respond_to do |format|
        format.html { redirect_to plans_meals_path, alert: 'Could not update meal plan.' }
        format.json { render json: { status: 'error' }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    date = @meal_plan.date
    @meal_plan.destroy
    redirect_to plans_meals_path(start_date: date.beginning_of_week), notice: 'Meal removed from plan.'
  end

  private

  def set_trip
    if params[:trip_id]
      # Find trips user owns OR is a member of
      owned_trips = Current.user.trips.where(id: params[:trip_id])
      member_trips = Trip.joins(:trip_members)
                        .where(trip_members: { user: Current.user }, id: params[:trip_id])
      
      trip_relation = Trip.where(id: [owned_trips.pluck(:id) + member_trips.pluck(:id)].flatten)
      @trip = trip_relation.first
      
      # Set context for views
      set_current_trip(@trip) if @trip
    else
      # Context-based routing - use the session trip
      @trip = current_trip
      unless @trip
        flash[:alert] = 'Please select a trip first.'
        redirect_to select_trip_path(return_to: request.path)
        return
      end
    end
    
    raise ActiveRecord::RecordNotFound unless @trip
  end

  def set_meal_plan
    @meal_plan = @trip.meal_plans.find(params[:id])
  end

  def meal_plan_params
    params.require(:meal_plan).permit(:recipe_id, :date, :meal_type, :description)
  end
end
