class ShoppingListAssignmentsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_shopping_list
  before_action :set_assignment, only: [ :record_purchase, :mark_complete, :clear_purchase ]

  def record_purchase
    @assignment.add_purchase!(params[:quantity])
    redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: "Purchase progress updated."
  rescue ArgumentError => e
    redirect_to trip_shopping_list_path(@trip, @shopping_list), alert: e.message
  end

  def mark_complete
    @assignment.mark_complete!
    redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: "Item marked as purchased."
  end

  def clear_purchase
    @assignment.clear_purchase!
    redirect_to trip_shopping_list_path(@trip, @shopping_list), notice: "Purchase progress cleared."
  end

  private

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
