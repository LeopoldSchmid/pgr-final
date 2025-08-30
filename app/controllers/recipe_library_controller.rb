class RecipeLibraryController < ApplicationController
  before_action :require_authentication
  
  def index
    @query = params[:q]&.strip
    @source_filter = params[:source_type]
    
    # Base query for all accessible recipes
    recipes_query = Recipe.includes(:user, :ingredients, :trip)
    
    # Apply search filter
    if @query.present?
      recipes_query = recipes_query.where("name ILIKE ? OR description ILIKE ?", "%#{@query}%", "%#{@query}%")
    end
    
    # Apply source type filter
    case @source_filter
    when 'public'
      @recipes = recipes_query.public_recipes
    when 'personal'
      @recipes = recipes_query.personal_recipes(Current.user)
    when 'trip'
      # Show trip recipes from user's trips
      user_trip_ids = Current.user.trips.pluck(:id) + 
                     Trip.joins(:trip_members).where(trip_members: { user: Current.user }).pluck(:id)
      @recipes = recipes_query.trip_recipes.where(trip_id: user_trip_ids)
    else
      # Show all accessible recipes
      user_trip_ids = Current.user.trips.pluck(:id) + 
                     Trip.joins(:trip_members).where(trip_members: { user: Current.user }).pluck(:id)
      
      @recipes = recipes_query.where(
        "source_type = 'public' OR " +
        "(source_type = 'personal' AND user_id = ?) OR " +
        "(source_type = 'trip' AND trip_id IN (?))",
        Current.user.id,
        user_trip_ids.any? ? user_trip_ids : [0]
      )
    end
    
    @recipes = @recipes.order(:name).limit(50)
    @recipe_counts = {
      all: @recipes.count,
      public: Recipe.public_recipes.count,
      personal: Recipe.personal_recipes(Current.user).count,
      trip: Recipe.trip_recipes.joins(:trip).where(
        trips: { id: (Current.user.trips.pluck(:id) + 
                     Trip.joins(:trip_members).where(trip_members: { user: Current.user }).pluck(:id)).uniq }
      ).count
    }
  end
  
  def copy
    @source_recipe = Recipe.find(params[:id])
    
    # Verify user can access this recipe
    unless can_access_recipe?(@source_recipe)
      redirect_to recipe_library_path, alert: 'Recipe not found.'
      return
    end
    
    @trip_id = params[:trip_id]
    
    if @trip_id.present?
      @trip = Current.user.trips.find(@trip_id)
      # Copy to trip with optional scaling
      servings = params[:servings]&.to_i
      copied_recipe = @source_recipe.copy_to_trip(@trip, servings)
      redirect_to trip_recipe_path(@trip, copied_recipe), notice: "Recipe copied to #{@trip.name}!"
    else
      # Copy to personal library
      name = params[:name].present? ? params[:name] : "#{@source_recipe.name} (My Version)"
      copied_recipe = @source_recipe.copy_to_personal(Current.user, name)
      redirect_to recipe_library_path, notice: "Recipe saved to your personal library!"
    end
  end
  
  private
  
  def can_access_recipe?(recipe)
    return true if recipe.is_public?
    return true if recipe.is_personal? && recipe.user == Current.user
    
    if recipe.is_trip_recipe?
      user_trip_ids = Current.user.trips.pluck(:id) + 
                     Trip.joins(:trip_members).where(trip_members: { user: Current.user }).pluck(:id)
      return user_trip_ids.include?(recipe.trip_id)
    end
    
    false
  end
end