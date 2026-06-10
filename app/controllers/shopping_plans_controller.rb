class ShoppingPlansController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context
  before_action :set_trip
  before_action :set_requirement, only: [ :create_assignment ]
  before_action :set_meal_plan, only: [ :mark_meal_source_brought ]
  before_action :store_last_plans_tab

  def show
    load_plan_data
  end

  def sync
    result = Shopping::RequirementSynchronizer.new(trip: @trip, user: Current.user).sync!
    redirect_to plans_shopping_path(trip_id: @trip.id), notice: sync_notice_for(result)
  end

  def undo_sync
    sync_run = @trip.shopping_sync_runs.find(params[:id])
    Shopping::UndoSync.new(sync_run).call
    redirect_to plans_shopping_path(trip_id: @trip.id), notice: "Last shopping sync was undone."
  end

  def create_manual_requirement
    @requirement = @trip.shopping_requirements.build(
      manual_requirement_attributes.merge(source_type: "manual", sync_status: "manual")
    )

    respond_to do |format|
      if @requirement.save
        load_plan_data
        format.turbo_stream
        format.html { redirect_to plans_shopping_path(trip_id: @trip.id), notice: "Manual shopping requirement added." }
      else
        @error = @requirement.errors.full_messages.to_sentence
        format.turbo_stream
        format.html { redirect_to plans_shopping_path(trip_id: @trip.id), alert: @error }
      end
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

  def mark_meal_source_brought
    result = Shopping::MealSourceCompleter.new(trip: @trip, meal_plan: @meal_plan).call
    redirect_to plans_shopping_path(trip_id: @trip.id), notice: "Marked #{result.completed_assignments.size} item(s) as brought for this meal."
  end

  def bulk_assign
    if params[:shopping_list_id].blank?
      redirect_to plans_shopping_path(trip_id: @trip.id), alert: "Select a shopping list."
      return
    end

    shopping_list = @trip.shopping_lists.find(params[:shopping_list_id])
    unassigned_requirements = @trip.shopping_requirements.select { |r| r.unassigned_quantity.positive? }

    assigned_ids = []
    unassigned_requirements.each do |req|
      assignment = Shopping::AssignmentSplitter.new(requirement: req).assign_to_list!(
        shopping_list: shopping_list,
        quantity: req.unassigned_quantity,
        unit: req.unit
      )
      assigned_ids << assignment.id
    end

    session[:last_bulk_assign_ids] = assigned_ids

    redirect_to plans_shopping_path(trip_id: @trip.id), notice: "Bulk assigned #{assigned_ids.size} items to #{shopping_list.name}."
  rescue ActiveRecord::RecordNotFound
    redirect_to plans_shopping_path(trip_id: @trip.id), alert: "Shopping list not found."
  end

  def undo_bulk_assign
    if session[:last_bulk_assign_ids].present?
      ShoppingListAssignment.where(id: session[:last_bulk_assign_ids]).destroy_all
      session.delete(:last_bulk_assign_ids)
      redirect_to plans_shopping_path(trip_id: @trip.id), notice: "Bulk assignment undone."
    else
      redirect_to plans_shopping_path(trip_id: @trip.id), alert: "Nothing to undo."
    end
  end

  def delete_selected
    requirements = @trip.shopping_requirements.where(id: selected_requirement_ids)

    if requirements.empty?
      redirect_to plans_shopping_path(trip_id: @trip.id), alert: "Nothing selected."
      return
    end

    deleted_count = requirements.count
    requirements.destroy_all
    redirect_to plans_shopping_path(trip_id: @trip.id), notice: "#{deleted_count} items deleted."
  end

  private

  def load_plan_data
    @shopping_lists = active_shopping_lists
    @shopping_requirements = @trip.shopping_requirements.includes(:shopping_list_assignments).ordered
    @sync_preview = Shopping::RequirementSynchronizer.new(trip: @trip, user: Current.user).preview
    @outdated_requirement_ids = @sync_preview[:changed].map { |pair| pair[:existing].id } + @sync_preview[:removed].map(&:id)
    @grouping_mode = selected_grouping_mode
    @grouped_requirements = grouped_requirements_for(@shopping_requirements, @grouping_mode)
    @last_sync_run = @trip.shopping_sync_runs.recent_first.first
    @food_item_picker_payload = FoodItem.order(:name).map do |food_item|
      {
        id: food_item.id,
        name: food_item.name,
        category: food_item.category,
        unit_type: food_item.unit_type,
        standard_unit: food_item.standard_unit,
        unit_suggestions: food_item.unit_suggestions
      }
    end
  end

  def set_trip
    @trip = resolved_trip
    raise ActiveRecord::RecordNotFound unless @trip
  end

  def set_requirement
    @requirement = @trip.shopping_requirements.find(params[:requirement_id])
  end

  def set_meal_plan
    @meal_plan = @trip.meal_plans.find(params[:meal_plan_id])
  end

  def active_shopping_lists
    lists = @trip.shopping_lists.where(archived_at: nil).order(:position, :created_at)
    return lists if lists.exists?

    @trip.shopping_lists.create!(name: "Trip Shopping List", status: "draft")
    @trip.shopping_lists.where(archived_at: nil).order(:position, :created_at)
  end

  def manual_requirement_params
    params.require(:shopping_requirement).permit(:food_item_id, :name, :quantity, :unit, :category, :notes)
  end

  def manual_requirement_attributes
    attributes = manual_requirement_params.to_h
    food_item = FoodItem.find_by(id: attributes["food_item_id"])

    # Base defaults for rapid-add, ensuring mobile inputs don't crash
    attributes["quantity"] = 1.0 if attributes["quantity"].blank?

    if food_item
      attributes["name"] = food_item.name if attributes["name"].blank?
      attributes["unit"] = food_item.standard_unit if attributes["unit"].blank?
      attributes["category"] = food_item.category if attributes["category"].blank?
      attributes["food_item_id"] = food_item.id
    end

    attributes["unit"] = "pieces" if attributes["unit"].blank?
    attributes["category"] = "other" if attributes["category"].blank?

    attributes
  end

  def selected_requirement_ids
    raw_ids = params[:requirement_ids]

    case raw_ids
    when String
      raw_ids.split(",")
    when Array
      raw_ids
    else
      []
    end.map(&:to_i).uniq
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

  def selected_grouping_mode
    mode = params[:group].presence || session[:shopping_plan_grouping].presence || "category"
    mode = %w[category source].include?(mode) ? mode : "category"
    session[:shopping_plan_grouping] = mode
    mode
  end

  def grouped_requirements_for(requirements, mode)
    grouped = requirements.group_by do |requirement|
      case mode
      when "source"
        requirement.source_label.presence || "-"
      else
        requirement.category.to_s.upcase
      end
    end

    grouped.sort_by { |label, _| [label == "-" ? 1 : 0, label.to_s.downcase] }
  end

  def store_last_plans_tab
    session[:last_plans_tab] = "shopping_plan"
  end
end
