require "test_helper"

class ShoppingItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "shopping_items_controller@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "Shopping Items Trip",
      start_date: Date.current,
      end_date: Date.current + 1.day
    )

    @shopping_list = @trip.shopping_lists.create!(
      name: "Trip Shopping",
      status: "draft"
    )

    @item = @shopping_list.shopping_items.create!(
      name: "Tomatoes",
      quantity: 2,
      purchased_quantity: 0,
      unit: "kg",
      category: "produce",
      source_type: "Manual"
    )

    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "create adds manual shopping item" do
    assert_difference("ShoppingItem.count", 1) do
      post trip_shopping_list_shopping_items_url(@trip, @shopping_list), params: {
        shopping_item: {
          name: "Beer",
          quantity: 12,
          unit: "bottles",
          category: "other"
        }
      }
    end

    created_item = ShoppingItem.order(:created_at).last
    assert_equal "Beer", created_item.name
    assert_equal "Manual", created_item.source_type
    assert_redirected_to plans_shopping_list_url(trip_id: @trip.id, list_id: @shopping_list.id)
  end

  test "record_purchase adds partial progress" do
    patch record_purchase_trip_shopping_list_shopping_item_url(@trip, @shopping_list, @item), params: {
      purchased_quantity: 1
    }

    assert_redirected_to plans_shopping_list_url(trip_id: @trip.id, list_id: @shopping_list.id)
    @item.reload
    assert_equal 1, @item.purchased_quantity
    assert_equal "partial", @item.purchase_status
  end

  test "record_purchase can mark item complete" do
    patch record_purchase_trip_shopping_list_shopping_item_url(@trip, @shopping_list, @item), params: {
      mark_complete: true
    }

    assert_redirected_to plans_shopping_list_url(trip_id: @trip.id, list_id: @shopping_list.id)
    @item.reload
    assert_equal 2, @item.purchased_quantity
    assert @item.fully_purchased?
  end

  test "record_purchase can clear progress" do
    @item.update!(purchased_quantity: 1)

    patch record_purchase_trip_shopping_list_shopping_item_url(@trip, @shopping_list, @item), params: {
      clear_purchase: true
    }

    assert_redirected_to plans_shopping_list_url(trip_id: @trip.id, list_id: @shopping_list.id)
    @item.reload
    assert_equal 0, @item.purchased_quantity
    assert_equal "open", @item.purchase_status
  end

  test "toggle_purchased still completes and resets trackable items" do
    patch toggle_purchased_trip_shopping_list_shopping_item_url(@trip, @shopping_list, @item)

    @item.reload
    assert_equal 2, @item.purchased_quantity
    assert @item.fully_purchased?

    patch toggle_purchased_trip_shopping_list_shopping_item_url(@trip, @shopping_list, @item)

    @item.reload
    assert_equal 0, @item.purchased_quantity
    assert_equal "open", @item.purchase_status
  end
end
