class ShoppingPlansController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context
  before_action :set_trip
  before_action :set_requirement, only: [ :create_assignment ]

  def show
    @shopping_lists = active_shopping_lists
    @shopping_requirements = @trip.shopping_requirements.includes(:shopping_list_assignments).ordered
    @sync_preview = Shopping::RequirementSynchronizer.new(trip: @trip, user: Current.user).preview
    @outdated_requirement_ids = @sync_preview[:changed].map { |pair| pair[:existing].id } + @sync_preview[:removed].map(&:id)
    @grouped_requirements = @shopping_requirements.group_by(&:category)
    @last_sync_run = @trip.shopping_sync_runs.recent_first.first
    @food_item_picker_payload = FoodItem.order(:name).map do |food_item|
      {
        id: food_item.id,
        name: food_item.name,
        category: food_item.category,
        standard_unit: food_item.standard_unit,
        unit_suggestions: food_item.unit_suggestions
      }
    end
  end

  def sync
    result = Shopping::RequirementSynchronizer.new(trip: @trip, user: Current.user).sync!
    redirect_to plans_shopping_path, notice: sync_notice_for(result)
  end

  def undo_sync
    sync_run = @trip.shopping_sync_runs.find(params[:id])
    Shopping::UndoSync.new(sync_run).call
    redirect_to plans_shopping_path, notice: "Last shopping sync was undone."
  end

  def create_manual_requirement
    requirement = @trip.shopping_requirements.build(
      manual_requirement_attributes.merge(source_type: "manual", sync_status: "manual")
    )

    if requirement.save
      redirect_to plans_shopping_path, notice: "Manual shopping requirement added."
    else
      redirect_to plans_shopping_path, alert: requirement.errors.full_messages.to_sentence
    end
  end

  def create_assignment
    if params[:shopping_list_id].blank?
      redirect_to plans_shopping_path(trip_id: @trip.id), alert: "Select a shopping list."
      return
    end

    shopping_list = @trip.shopping_lists.find(params[:shopping_list_id])
    Shopping::AssignmentSplitter.new(requirement: @requirement).assign_to_list!(
      shopping_list: shopping_list,
      quantity: params[:quantity],
      unit: params[:unit]
    )

    redirect_to plans_shopping_path(trip_id: @trip.id), notice: "Requirement assigned to #{shopping_list.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to plans_shopping_path(trip_id: @trip.id), alert: "Shopping list not found."
  rescue ArgumentError => e
    redirect_to plans_shopping_path(trip_id: @trip.id), alert: e.message
  end

  private

  def set_trip
    @trip = resolved_trip
    raise ActiveRecord::RecordNotFound unless @trip
  end

  def set_requirement
    @requirement = @trip.shopping_requirements.find(params[:requirement_id])
  end

  def active_shopping_lists
    @trip.shopping_lists.where(archived_at: nil).order(:position, :created_at)
  end

  def manual_requirement_params
    params.require(:shopping_requirement).permit(:food_item_id, :name, :quantity, :unit, :category, :notes)
  end

  def manual_requirement_attributes
    attributes = manual_requirement_params.to_h
    food_item = FoodItem.find_by(id: attributes["food_item_id"])
    return attributes unless food_item

    attributes["name"] = food_item.name if attributes["name"].blank?
    attributes["unit"] = food_item.standard_unit if attributes["unit"].blank?
    attributes["category"] = food_item.category if attributes["category"].blank?
    attributes["food_item_id"] = food_item.id
    attributes
  end

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

  def sync_notice_for(result)
    [
      "Shopping plan synchronized.",
      "#{result.created.size} created, #{result.updated.size} updated, #{result.removed.compact.size} removed."
    ].join(" ")
  end
end
