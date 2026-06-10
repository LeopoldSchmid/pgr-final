class MealPlansController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_meal_plan, only: [:update, :destroy, :duplicate, :add_to_shopping_plan, :update_ingredients, :set_assignees, :drift_preview, :resolve_drift]

  def index
    @meal_plans = @trip.meal_plans.includes(:recipe).ordered
    @recipes = accessible_recipes
    
    # Default to current week or trip start date
    @start_date = params[:start_date] ? Date.parse(params[:start_date]) : Date.today.beginning_of_week
    @end_date = @start_date.end_of_week
    
    @planned_meals = @meal_plans.group_by(&:date).transform_values { |plans| plans.group_by(&:meal_type) }
  end

  def create
    @meal_plan = @trip.meal_plans.build(base_meal_plan_attributes)
    @meal_plan.recipe = resolve_recipe_for_create
    assign_assignees(@meal_plan, meal_plan_params[:assignee_ids])

    if @meal_plan.save
      redirect_to meals_day_path(@meal_plan.date), notice: "Meal scheduled successfully."
    else
      redirect_to meals_day_path(@meal_plan.date), alert: "Could not schedule meal."
    end
  rescue ArgumentError => e
    redirect_to meals_day_path(parsed_meal_date || Date.current), alert: e.message
  end

  def update
    assign_assignees(@meal_plan, meal_plan_params[:assignee_ids]) if meal_plan_params.key?(:assignee_ids)

    if @meal_plan.update(base_meal_plan_attributes)
      respond_to do |format|
        format.html { redirect_to meals_day_path(@meal_plan.date), notice: "Meal plan updated." }
        format.json { render json: { status: "success" } }
      end
    else
      respond_to do |format|
        format.html { redirect_to meals_day_path(@meal_plan.date), alert: "Could not update meal plan." }
        format.json { render json: { status: "error" }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    date = @meal_plan.date
    @meal_plan.destroy
    redirect_to meals_day_path(date), notice: "Meal removed from plan."
  end

  def duplicate
    created = duplicate_meal_plan!
    earliest_date = created.map(&:date).min || @meal_plan.date
    redirect_to meals_day_path(earliest_date), notice: "#{created.size} meal(s) duplicated."
  rescue ArgumentError => e
    redirect_to meals_day_path(@meal_plan.date), alert: e.message
  end

  def set_assignees
    assign_assignees(@meal_plan, params[:assignee_ids])
    @meal_plan.save! if @meal_plan.changed?
    redirect_to meals_day_path(@meal_plan.date), notice: "Assignees updated."
  end

  def add_to_shopping_plan
    Shopping::RequirementSynchronizer.new(trip: @trip, user: Current.user).sync!

    redirect_to plans_meals_path(
      trip_id: @trip.id,
      start_date: @meal_plan.date.beginning_of_week,
      selected_date: @meal_plan.date
    ), notice: "Shopping plan updated."
  end

  def update_ingredients
    recipe = @meal_plan.recipe
    unless recipe.trip_id == @trip.id
      redirect_to meals_day_path(@meal_plan.date), alert: "Ingredients can only be edited for trip recipes."
      return
    end

    if recipe.update(recipe_ingredient_params)
      redirect_to meals_day_path(@meal_plan.date), notice: "Ingredients updated."
    else
      redirect_to meals_day_path(@meal_plan.date), alert: recipe.errors.full_messages.to_sentence
    end
  end

  def drift_preview
    @meal_plan.refresh_drift_status!
    render json: @meal_plan.drift_preview
  end

  def resolve_drift
    strategy = params[:strategy].to_s
    unless %w[accept_new_recipe keep_current].include?(strategy)
      redirect_to meals_day_path(@meal_plan.date), alert: "Invalid drift resolution strategy."
      return
    end

    @meal_plan.resolve_drift!(strategy: strategy)
    notice = strategy == "accept_new_recipe" ? "Recipe changes accepted for this meal." : "Drift acknowledged for this meal."
    redirect_to meals_day_path(@meal_plan.date), notice: notice
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
        flash[:alert] = "Please select a trip first."
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
    params.require(:meal_plan).permit(:recipe_id, :date, :meal_type, :description, :servings, :custom_name, assignee_ids: [])
  end

  def accessible_recipes
    trip_ids = (Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)).uniq

    Recipe.where(
      "source_type = 'public' OR (source_type = 'personal' AND user_id = ?) OR (source_type = 'trip' AND trip_id IN (?))",
      Current.user.id,
      trip_ids.presence || [0]
    ).order(:name)
  end

  def resolve_recipe_for_create
    recipe_id = meal_plan_params[:recipe_id].presence
    return accessible_recipes.find(recipe_id) if recipe_id

    custom_name = meal_plan_params[:custom_name].to_s.strip
    raise ArgumentError, "Choose a recipe or provide a custom meal name." if custom_name.blank?

    @trip.recipes.create!(
      name: custom_name,
      description: "Placeholder meal for planning",
      servings: meal_plan_params[:servings].presence || 1,
      source_type: "trip",
      user: Current.user
    )
  end

  def duplicate_meal_plan!
    target_dates = duplication_target_dates
    raise ArgumentError, "Choose at least one target day for duplication." if target_dates.empty?

    series_token = duplication_series_token
    target_dates.map do |target_date|
      @trip.meal_plans.create!(
        recipe: @meal_plan.recipe,
        date: target_date,
        meal_type: @meal_plan.meal_type,
        description: @meal_plan.description,
        servings: @meal_plan.servings,
        series_token: series_token
      ).tap do |copy|
        copy.meal_plan_assignees.insert_all(
          @meal_plan.meal_plan_assignees.pluck(:user_id).map do |user_id|
            { meal_plan_id: copy.id, user_id: user_id, created_at: Time.current, updated_at: Time.current }
          end
        ) if @meal_plan.meal_plan_assignees.any?
      end
    end
  end

  def duplication_target_dates
    source_date = @meal_plan.date
    mode = params[:target_mode].to_s

    dates = case mode
    when "next_day"
      [ source_date + 1.day ]
    when "rest_of_trip"
      range_start = [ source_date + 1.day, @trip.start_date ].max
      range_end = @trip.end_date
      range_start <= range_end ? (range_start..range_end).to_a : []
    when "selected_days"
      Array(params[:target_dates]).map { |value| Date.parse(value.to_s) rescue nil }.compact
    else
      []
    end

    dates.select { |day| day >= @trip.start_date && day <= @trip.end_date }.uniq.sort
  end

  def duplication_series_token
    return nil unless ActiveModel::Type::Boolean.new.cast(params[:link_series])

    @meal_plan.series_token.presence || SecureRandom.hex(8)
  end

  def assign_assignees(meal_plan, raw_ids)
    allowed_ids = @trip.trip_members.active_members.pluck(:user_id)
    ids = Array(raw_ids).map(&:to_i).uniq & allowed_ids

    meal_plan.meal_plan_assignees.where.not(user_id: ids).destroy_all
    existing_ids = meal_plan.meal_plan_assignees.pluck(:user_id)

    (ids - existing_ids).each do |user_id|
      if meal_plan.persisted?
        meal_plan.meal_plan_assignees.create!(user_id: user_id)
      else
        meal_plan.meal_plan_assignees.build(user_id: user_id)
      end
    end
  end

  def base_meal_plan_attributes
    meal_plan_params.except(:custom_name, :assignee_ids)
  end

  def recipe_ingredient_params
    params.require(:recipe).permit(ingredients_attributes: [:id, :name, :quantity, :unit, :category, :food_item_id, :_destroy])
  end

  def meals_day_path(date)
    plans_meals_path(trip_id: @trip.id, start_date: date.beginning_of_week, selected_date: date)
  end

  def parsed_meal_date
    Date.parse(meal_plan_params[:date].to_s)
  rescue ArgumentError, TypeError
    nil
  end
end
