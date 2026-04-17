class ShoppingItemsController < ApplicationController
  before_action :require_authentication
  before_action :set_trip_and_shopping_list
  before_action :set_shopping_item, only: [ :update, :destroy, :toggle_purchased, :record_purchase ]

  def create
    @shopping_item = @shopping_list.shopping_items.build(shopping_item_params)
    @shopping_item.source_type = "Manual"

    if @shopping_item.save
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: "Item added to shopping list!"
    else
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), alert: "Could not add item to shopping list."
    end
  end

  def update
    if @shopping_item.update(shopping_item_params)
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: "Item updated!"
    else
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), alert: "Could not update item."
    end
  end

  def destroy
    @shopping_item.destroy
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: "Item removed from shopping list."
  end

  def toggle_purchased
    @shopping_item.toggle_purchased!
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id)
  end

  def record_purchase
    if params[:clear_purchase].present?
      @shopping_item.clear_purchase!
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: "Purchase progress cleared."
      return
    end

    if params[:mark_complete].present?
      @shopping_item.mark_complete!
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: "Item marked as fully purchased."
      return
    end

    amount = params[:purchased_quantity]

    if amount.blank?
      redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), alert: "Enter how much was purchased."
      return
    end

    @shopping_item.add_purchase!(amount)
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), notice: "Purchase progress updated."
  rescue ArgumentError => e
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), alert: e.message
  rescue ActiveRecord::RecordInvalid => e
    redirect_to plans_shopping_list_path(trip_id: @trip.id, list_id: @shopping_list.id), alert: e.record.errors.full_messages.to_sentence
  end

  private

  def set_trip_and_shopping_list
    # Find trips user owns OR is a member of
    owned_trips = Current.user.trips.where(id: params[:trip_id])
    member_trips = Trip.joins(:trip_members)
                      .where(trip_members: { user: Current.user }, id: params[:trip_id])

    trip_relation = Trip.where(id: [ owned_trips.pluck(:id) + member_trips.pluck(:id) ].flatten)
    @trip = trip_relation.first

    raise ActiveRecord::RecordNotFound unless @trip

    @shopping_list = @trip.shopping_lists.find(params[:shopping_list_id])
  end

  def set_shopping_item
    @shopping_item = @shopping_list.shopping_items.find(params[:id])
  end

  def shopping_item_params
    params.require(:shopping_item).permit(:name, :quantity, :unit, :category, :purchased, :purchased_quantity)
  end
end
