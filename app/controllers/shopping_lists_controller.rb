class ShoppingListsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_shopping_list, only: [:show, :update, :generate_from_recipes, :add_manual_item]
  
  def index
    @shopping_lists = @trip.shopping_lists.order(created_at: :desc)
    @current_list = @shopping_lists.where(status: %w[draft active]).first
    redirect_to trip_shopping_list_path(@trip, @current_list) if @current_list
  end
  
  def show
    @items_by_category = @shopping_list.items_by_category
    @remaining_items = @shopping_list.shopping_items.remaining
    @purchased_items = @shopping_list.shopping_items.purchased
  end
  
  def create
    @shopping_list = @trip.shopping_lists.build(shopping_list_params)
    
    if @shopping_list.save
      redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: 'Shopping list created successfully.'
    else
      redirect_to trip_shopping_lists_path(@trip), alert: 'Could not create shopping list.'
    end
  end
  
  def update
    if @shopping_list.update(shopping_list_params)
      redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: 'Shopping list updated successfully.'
    else
      redirect_to trip_shopping_list_path(@trip, @shopping_list), alert: 'Could not update shopping list.'
    end
  end
  
  def generate_from_recipes
    recipe_ids = params[:recipe_ids]&.split(',')&.map(&:to_i) || []
    selected_recipes = @trip.recipes.where(id: recipe_ids)
    
    if selected_recipes.any?
      people_count = params[:people_count]&.to_i
      @shopping_list.generate_from_recipes(selected_recipes, people_count)
      @shopping_list.update!(status: 'active')
      
      redirect_to trip_shopping_list_path(@trip, @shopping_list), 
        notice: "Generated shopping list from #{pluralize(selected_recipes.count, 'recipe')}!"
    else
      redirect_to trip_recipes_path(@trip), alert: 'Please select some recipes first.'
    end
  end
  
  def add_manual_item
    item_params = params.require(:shopping_item).permit(:name, :quantity, :unit, :category)
    @shopping_list.add_manual_item(
      item_params[:name],
      item_params[:quantity],
      item_params[:unit],
      item_params[:category]
    )
    
    redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: 'Item added to shopping list!'
  end
  
  private
  
  def set_trip
    # Find trips user owns OR is a member of
    owned_trips = Current.user.trips.where(id: params[:trip_id])
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, id: params[:trip_id])
    
    trip_relation = Trip.where(id: [owned_trips.pluck(:id) + member_trips.pluck(:id)].flatten)
    @trip = trip_relation.first
    
    raise ActiveRecord::RecordNotFound unless @trip
  end
  
  def set_shopping_list
    @shopping_list = @trip.shopping_lists.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @shopping_list = ShoppingList.current_for_trip(@trip)
  end
  
  def shopping_list_params
    params.require(:shopping_list).permit(:name, :status)
  end
end
