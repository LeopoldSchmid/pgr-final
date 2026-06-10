require "test_helper"

class ShoppingListAssignmentTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email_address: "shopping_list_assignment_test@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Assignment Trip", start_date: Date.current, end_date: Date.current + 2.days)
    @shopping_list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
    @requirement = @trip.shopping_requirements.create!(
      name: "Tomatoes",
      quantity: 2,
      unit: "kg",
      category: "produce",
      source_type: "manual",
      sync_status: "manual"
    )
  end

  test "tracks remaining quantity and purchase status" do
    assignment = @requirement.shopping_list_assignments.create!(
      shopping_list: @shopping_list,
      planned_quantity: 2,
      purchased_quantity: 0,
      unit: "kg"
    )

    assert_equal 2, assignment.remaining_quantity
    assert_equal "open", assignment.purchase_status

    assignment.add_purchase!(1)
    assignment.reload
    assert_equal 1, assignment.remaining_quantity
    assert_equal "partial", assignment.purchase_status
    assert_equal "purchase", assignment.completion_source

    assignment.mark_complete!(source: "brought_by_meal_source")
    assignment.reload
    assert_equal 0, assignment.remaining_quantity
    assert_equal "done", assignment.purchase_status
    assert_equal "brought_by_meal_source", assignment.completion_source

    assignment.clear_purchase!
    assignment.reload
    assert_equal 0, assignment.purchased_quantity
    assert_nil assignment.completion_source
  end
end
