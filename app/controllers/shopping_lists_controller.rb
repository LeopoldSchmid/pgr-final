class ShoppingListsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_shopping_list, only: [ :show, :update, :generate_from_meal_plan, :add_manual_item ]

  def index
    @shopping_lists = @trip.shopping_lists.order(created_at: :desc)
    @current_list = @shopping_lists.where(status: %w[draft active]).first
    redirect_to trip_shopping_list_path(@trip, @current_list) if @current_list
  end

  def current
    @shopping_list = @trip.shopping_lists.where(archived_at: nil).order(:position, :created_at).first ||
      @trip.shopping_lists.create!(name: "General", status: "draft")

    redirect_to trip_shopping_list_path(@trip, @shopping_list)
  end

  def show
    @aggregated_assignments = Shopping::AssignmentAggregator.new(@shopping_list).call
    @assignment_groups = @aggregated_assignments.group_by(&:category)
    @open_assignment_count = @aggregated_assignments.count { |item| item.remaining_quantity.positive? }
    @done_assignment_count = @aggregated_assignments.count { |item| item.remaining_quantity.zero? }

    @items_by_category = @shopping_list.items_by_category
    @remaining_items = @shopping_list.shopping_items.remaining
    @purchased_items = @shopping_list.shopping_items.purchased
    @partial_items = @shopping_list.shopping_items.partial
  end

  def create
    @shopping_list = @trip.shopping_lists.build(shopping_list_params)

    if @shopping_list.save
      redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: "Shopping list created successfully."
    else
      redirect_to trip_shopping_lists_path(@trip), alert: "Could not create shopping list."
    end
  end

  def update
    if @shopping_list.update(shopping_list_params)
      redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: "Shopping list updated successfully."
    else
      redirect_to trip_shopping_list_path(@trip, @shopping_list), alert: "Could not update shopping list."
    end
  end

  def generate_from_meal_plan
    meal_plans = @trip.meal_plans.includes(:recipe)

    if meal_plans.any?
      people_count = params[:people_count]&.to_i
      @shopping_list.generate_from_meal_plan(meal_plans, people_count)
      @shopping_list.update!(status: "active")

      redirect_to trip_shopping_list_path(@trip, @shopping_list),
        notice: "Generated shopping list from #{view_context.pluralize(meal_plans.count, 'planned meal')}!"
    else
      redirect_to plans_meals_path, alert: "Please plan some meals first."
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

    redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: "Item added to shopping list!"
  end

  private

  def set_trip
    if params[:trip_id].blank?
      @trip = current_trip
      raise ActiveRecord::RecordNotFound unless @trip
      return
    end

    user = Current.session&.user || Current.user
    raise ActiveRecord::RecordNotFound unless user

    # Find trips user owns OR is a member of
    owned_trips = user.trips.where(id: params[:trip_id])
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: user }, id: params[:trip_id])

    trip_relation = Trip.where(id: [ owned_trips.pluck(:id) + member_trips.pluck(:id) ].flatten)
    @trip = trip_relation.first

    raise ActiveRecord::RecordNotFound unless @trip
  end

  def set_shopping_list
    @shopping_list = @trip.shopping_lists.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    @shopping_list = ShoppingList.current_for_trip(@trip)
  end

  def shopping_list_params
    params.require(:shopping_list).permit(:name, :status, :description, :position)
  end
end
