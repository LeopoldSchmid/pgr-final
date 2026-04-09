class RecipesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_recipe, only: [ :show, :edit, :update, :destroy ]

  def index
    @recipes = @trip.recipes.includes(:ingredients).order(:name)
  end

  def show
    @ingredients = @recipe.ingredients.order(:category, :name)
  end

  def new
    @recipe = @trip.recipes.build
    @recipe.ingredients.build # Pre-build one empty ingredient form
  end

  def create
    @recipe = @trip.recipes.build(recipe_params)
    @recipe.user = Current.user

    if @recipe.save
      redirect_to trip_recipes_path(@trip), notice: "Recipe was successfully created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    # Always ensure there's one empty ingredient row for easy adding
    @recipe.ingredients.build
  end

  def update
    if @recipe.update(recipe_params)
      redirect_to trip_recipe_path(@trip, @recipe), notice: "Recipe was successfully updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @recipe.destroy
    redirect_to trip_recipes_path(@trip), notice: "Recipe was deleted."
  end

  private

  def set_trip
    if params[:trip_id]
      # Find trips user owns OR is a member of
      owned_trips = Current.user.trips.where(id: params[:trip_id])
      member_trips = Trip.joins(:trip_members)
                        .where(trip_members: { user: Current.user }, id: params[:trip_id])

      trip_relation = Trip.where(id: [ owned_trips.pluck(:id) + member_trips.pluck(:id) ].flatten)
      @trip = trip_relation.first

      # Set context for views
      set_current_trip(@trip) if @trip
    else
      # Context-based routing - use the session trip
      @trip = current_trip
    end

    raise ActiveRecord::RecordNotFound unless @trip
  end

  def set_recipe
    @recipe = @trip.recipes.find(params[:id])
  end

  def recipe_params
    params.require(:recipe).permit(:name, :servings, :description,
      ingredients_attributes: [ :id, :name, :quantity, :unit, :category, :food_item_id, :_destroy ])
  end
end
