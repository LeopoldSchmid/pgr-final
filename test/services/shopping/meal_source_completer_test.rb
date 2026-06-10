require "test_helper"

module Shopping
  class MealSourceCompleterTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(email_address: "meal_source_completer@example.com", password: "password123", locale: "en")
      @trip = Trip.create!(user: @user, name: "Completer Trip", start_date: Date.current, end_date: Date.current + 2.days)
      @shopping_list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")

      @recipe = Recipe.create!(name: "Bruschetta", description: "Dinner", servings: 2, trip: @trip, user: @user)
      @recipe.ingredients.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce")
      @meal_plan = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "dinner")

      Shopping::RequirementSynchronizer.new(trip: @trip, user: @user).sync!
    end

    test "completes all meal-source requirements and assignments" do
      requirement = @trip.shopping_requirements.first
      requirement.shopping_list_assignments.create!(shopping_list: @shopping_list, planned_quantity: 0.5, purchased_quantity: 0, unit: "kg")

      result = MealSourceCompleter.new(trip: @trip, meal_plan: @meal_plan).call

      assert result.completed_assignments.any?
      assert_equal 0, requirement.reload.unassigned_quantity.to_d
      assert requirement.shopping_list_assignments.all? { |a| a.remaining_quantity.zero? }
      assert requirement.shopping_list_assignments.all? { |a| a.completion_source == "brought_by_meal_source" }
    end
  end
end
