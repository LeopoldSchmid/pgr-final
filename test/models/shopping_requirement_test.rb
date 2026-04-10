require "test_helper"

class ShoppingRequirementTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email_address: "shopping_requirement_test@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Requirement Trip", start_date: Date.current, end_date: Date.current + 2.days)
    @shopping_list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
  end

  test "tracks assigned and over-assigned quantities" do
    requirement = @trip.shopping_requirements.create!(
      name: "Tomatoes",
      quantity: 2,
      unit: "kg",
      category: "produce",
      source_type: "manual",
      sync_status: "manual"
    )

    requirement.shopping_list_assignments.create!(shopping_list: @shopping_list, planned_quantity: 1, purchased_quantity: 0, unit: "kg")

    assert_equal 1, requirement.assigned_quantity
    assert_equal 1, requirement.unassigned_quantity
    assert_equal 0, requirement.over_assigned_quantity

    requirement.shopping_list_assignments.create!(shopping_list: @trip.shopping_lists.create!(name: "Market", status: "draft"), planned_quantity: 1.5, purchased_quantity: 0, unit: "kg")

    assert_equal 2.5, requirement.assigned_quantity
    assert_equal 0, requirement.unassigned_quantity
    assert_equal 0.5, requirement.over_assigned_quantity
  end

  test "manual source gets manual sync status by default" do
    requirement = @trip.shopping_requirements.create!(
      name: "Beer",
      quantity: 3,
      unit: "l",
      category: "other",
      source_type: "manual"
    )

    assert_equal "manual", requirement.sync_status
  end
end
