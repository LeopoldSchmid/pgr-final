require "test_helper"

module Shopping
  class AssignmentSplitterTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(email_address: "shopping_assignment_splitter@example.com", password: "password123", locale: "en")
      @trip = Trip.create!(user: @user, name: "Split Trip", start_date: Date.current, end_date: Date.current + 2.days)
      @aldi = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
      @market = @trip.shopping_lists.create!(name: "Market", status: "draft")
      @requirement = @trip.shopping_requirements.create!(
        name: "Tomatoes",
        quantity: 2,
        unit: "kg",
        category: "produce",
        source_type: "manual",
        sync_status: "manual"
      )
    end

    test "splits a requirement across multiple lists" do
      splitter = AssignmentSplitter.new(requirement: @requirement)

      splitter.assign_to_list!(shopping_list: @aldi, quantity: 1, unit: "kg")
      splitter.assign_to_list!(shopping_list: @market, quantity: 1000, unit: "g")

      assert_equal 2, @requirement.shopping_list_assignments.count
      assert_equal 0, @requirement.unassigned_quantity
    end

    test "rejects assigning more than the remaining quantity" do
      splitter = AssignmentSplitter.new(requirement: @requirement)
      splitter.assign_to_list!(shopping_list: @aldi, quantity: 1.5, unit: "kg")

      error = assert_raises(ArgumentError) do
        splitter.assign_to_list!(shopping_list: @market, quantity: 1, unit: "kg")
      end

      assert_match(/exceeds remaining requirement/, error.message)
    end
  end
end
