require "test_helper"

module Shopping
  class AssignmentAggregatorTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(email_address: "shopping_assignment_aggregator@example.com", password: "password123", locale: "en")
      @trip = Trip.create!(user: @user, name: "Aggregator Trip", start_date: Date.current, end_date: Date.current + 2.days)
      @shopping_list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
      @tomatoes = FoodItem.create!(name: "Tomatoes", standard_unit: "kg", category: "produce", unit_type: "weight")
    end

    test "aggregates compatible assignments and flags comments" do
      req_one = @trip.shopping_requirements.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce", source_type: "manual", sync_status: "manual", food_item: @tomatoes, source_label: "Meal 1")
      req_two = @trip.shopping_requirements.create!(name: "Tomatoes", quantity: 500, unit: "g", category: "produce", source_type: "manual", sync_status: "manual", food_item: @tomatoes, source_label: "Meal 2")

      assignment_one = req_one.shopping_list_assignments.create!(shopping_list: @shopping_list, planned_quantity: 1, purchased_quantity: 0.5, unit: "kg")
      assignment_two = req_two.shopping_list_assignments.create!(shopping_list: @shopping_list, planned_quantity: 500, purchased_quantity: 0, unit: "g")
      assignment_two.shopping_item_comments.create!(user: @user, body: "Buy later")

      items = AssignmentAggregator.new(@shopping_list).call

      assert_equal 1, items.length
      item = items.first
      assert_equal "Tomatoes", item.name
      assert_equal 1.5, item.planned_quantity
      assert_equal 0.5, item.purchased_quantity
      assert_equal 1.0, item.remaining_quantity
      assert_equal true, item.has_comments
      assert_equal [ assignment_one, assignment_two ].sort_by(&:id), item.assignments.sort_by(&:id)
    end
  end
end
