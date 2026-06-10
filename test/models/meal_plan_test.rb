require "test_helper"

class MealPlanTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(email_address: "meal_plan_model@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Meal Plan Model Trip", start_date: Date.current, end_date: Date.current + 2.days)
    @recipe = Recipe.create!(name: "Pasta", description: "Simple", servings: 4, trip: @trip, user: @user)
    @recipe.ingredients.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce")
  end

  test "accepts extended meal types and defaults servings" do
    meal = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "drinks")

    assert_equal 4, meal.servings.to_f
    assert_equal "in_sync", meal.drift_status
    assert meal.recipe_snapshot_signature.present?
  end

  test "detects drift when recipe ingredients change" do
    meal = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "miscellaneous")
    assert_not meal.drifted?

    @recipe.ingredients.first.update!(quantity: 2)

    assert meal.reload.drifted?
  end

  test "flags missing ingredients for initial planning" do
    empty_recipe = Recipe.create!(name: "Plan Placeholder", description: "", servings: 2, trip: @trip, user: @user)
    meal = MealPlan.create!(trip: @trip, recipe: empty_recipe, date: Date.current, meal_type: "breakfast")

    assert meal.ingredients_missing?
  end
end
