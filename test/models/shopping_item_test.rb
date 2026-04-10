require "test_helper"

class ShoppingItemTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "shopping_item_test@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "Shopping Item Trip",
      start_date: Date.current,
      end_date: Date.current + 2.days
    )

    @shopping_list = @trip.shopping_lists.create!(
      name: "Trip Shopping",
      status: "draft"
    )
  end

  test "trackable item derives remaining quantity and status" do
    item = @shopping_list.shopping_items.create!(
      name: "Tomatoes",
      quantity: 2,
      unit: "kg",
      category: "produce",
      source_type: "Manual"
    )

    assert_equal 2, item.remaining_quantity
    assert_equal "open", item.purchase_status

    item.add_purchase!(1)
    item.reload

    assert_equal 1, item.remaining_quantity
    assert_equal "partial", item.purchase_status

    item.mark_complete!
    item.reload

    assert_equal 0, item.remaining_quantity
    assert_equal "done", item.purchase_status
    assert item.purchased?
  end

  test "toggle purchased completes and clears trackable items" do
    item = @shopping_list.shopping_items.create!(
      name: "Bread",
      quantity: 1,
      unit: "pcs",
      category: "pantry",
      source_type: "Manual"
    )

    item.toggle_purchased!
    item.reload
    assert_equal 1, item.purchased_quantity
    assert item.fully_purchased?

    item.toggle_purchased!
    item.reload
    assert_equal 0, item.purchased_quantity
    assert_equal "open", item.purchase_status
  end

  test "completion percentage uses quantities for progress" do
    @shopping_list.shopping_items.create!(
      name: "Tomatoes",
      quantity: 2,
      purchased_quantity: 1,
      unit: "kg",
      category: "produce",
      source_type: "Manual"
    )

    @shopping_list.shopping_items.create!(
      name: "Salt",
      quantity: 1,
      purchased_quantity: 1,
      unit: "tsp",
      category: "spices",
      source_type: "Manual"
    )

    assert_equal 67, @shopping_list.completion_percentage
  end

  test "manual items with quantity require a unit" do
    item = @shopping_list.shopping_items.build(
      name: "Tomatoes",
      quantity: 2,
      category: "produce",
      source_type: "Manual"
    )

    assert_not item.valid?
    assert_includes item.errors[:unit], "can't be blank"
  end
end
