class ShoppingListAssignmentsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_shopping_list
  before_action :set_assignment, only: [ :record_purchase, :mark_complete, :clear_purchase ]

  def record_purchase
    @assignment.add_purchase!(params[:quantity])
    respond_with_turbo_update("Purchase progress updated.")
  rescue ArgumentError => e
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), alert: e.message
  end

  def mark_complete
    @assignment.mark_complete!
    respond_with_turbo_update("Item marked as purchased.")
  end

  def clear_purchase
    @assignment.clear_purchase!
    respond_with_turbo_update("Purchase progress cleared.")
  end

  private

  def respond_with_turbo_update(notice_msg)
    respond_to do |format|
      format.turbo_stream do
        aggregated_items = Shopping::AssignmentAggregator.new(@shopping_list).call
        @item = aggregated_items.find { |i| i.assignments.map(&:id).include?(@assignment.id) }
        
        open_count = aggregated_items.count { |i| i.remaining_quantity.positive? }
        done_count = aggregated_items.count { |i| i.remaining_quantity.zero? }
        
        render turbo_stream: [
          turbo_stream.replace("item_#{@item.key.parameterize}", partial: "shopping_lists/item", locals: { item: @item, trip: @trip, shopping_list: @shopping_list }),
          turbo_stream.replace("stats_bar", partial: "shopping_lists/stats", locals: { open_count: open_count, done_count: done_count, items_count: aggregated_items.count })
        ]
      end
      format.html { redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: notice_msg }
    end
  end

  def set_trip
    user = Current.session&.user || Current.user
    raise ActiveRecord::RecordNotFound unless user

    owned_trips = user.trips.where(id: params[:trip_id])
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: user }, id: params[:trip_id])

    @trip = Trip.where(id: [ owned_trips.pluck(:id) + member_trips.pluck(:id) ].flatten).first
    raise ActiveRecord::RecordNotFound unless @trip
  end

  def set_shopping_list
    @shopping_list = @trip.shopping_lists.find(params[:shopping_list_id])
  end

  def set_assignment
    @assignment = @shopping_list.shopping_list_assignments.find(params[:id])
  end
end
