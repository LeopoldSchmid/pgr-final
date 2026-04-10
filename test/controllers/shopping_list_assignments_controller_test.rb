require "test_helper"

class ShoppingListAssignmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "shopping_list_assignments_controller@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Execution Trip", start_date: Date.current, end_date: Date.current + 3.days)
    @list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
    @requirement = @trip.shopping_requirements.create!(
      name: "Tomatoes",
      quantity: 2,
      unit: "kg",
      category: "produce",
      source_type: "manual",
      sync_status: "manual"
    )
    @assignment = @requirement.shopping_list_assignments.create!(shopping_list: @list, planned_quantity: 2, purchased_quantity: 0, unit: "kg")

    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "records partial purchase" do
    patch record_purchase_trip_shopping_list_shopping_list_assignment_url(@trip, @list, @assignment), params: { quantity: 1 }

    assert_redirected_to trip_shopping_list_url(@trip, @list)
    assert_equal 1, @assignment.reload.purchased_quantity
  end

  test "marks assignment complete" do
    patch mark_complete_trip_shopping_list_shopping_list_assignment_url(@trip, @list, @assignment)

    assert_redirected_to trip_shopping_list_url(@trip, @list)
    assert_equal 2, @assignment.reload.purchased_quantity
  end

  test "clears purchase progress" do
    @assignment.update!(purchased_quantity: 1)

    patch clear_purchase_trip_shopping_list_shopping_list_assignment_url(@trip, @list, @assignment)

    assert_redirected_to trip_shopping_list_url(@trip, @list)
    assert_equal 0, @assignment.reload.purchased_quantity
  end
end
