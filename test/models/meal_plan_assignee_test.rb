require "test_helper"

class MealPlanAssigneeTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email_address: "meal_plan_assignee_user@example.com", password: "password123", locale: "en")
    @second_user = User.create!(email_address: "meal_plan_assignee_other@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Assignee Trip", start_date: Date.current, end_date: Date.current + 2.days)
    @recipe = Recipe.create!(name: "Risotto", description: "Dinner", servings: 3, trip: @trip, user: @user)
    @meal_plan = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "dinner")
  end

  test "enforces uniqueness of user per meal plan" do
    MealPlanAssignee.create!(meal_plan: @meal_plan, user: @user)

    duplicate = MealPlanAssignee.new(meal_plan: @meal_plan, user: @user)
    assert_not duplicate.valid?
  end

  test "allows multiple assignees on one meal" do
    MealPlanAssignee.create!(meal_plan: @meal_plan, user: @user)

    assert_difference("@meal_plan.meal_plan_assignees.count", 1) do
      MealPlanAssignee.create!(meal_plan: @meal_plan, user: @second_user)
    end
  end
end
