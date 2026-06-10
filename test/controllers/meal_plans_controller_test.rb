require "test_helper"

class MealPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "meal_plans_controller@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Meal Controller Trip", start_date: Date.current, end_date: Date.current + 5.days)
    @member = User.create!(email_address: "meal_plans_member@example.com", password: "password123", locale: "en")
    @trip.add_member(@member)

    @recipe = Recipe.create!(name: "Pasta", description: "Dinner", servings: 4, trip: @trip, user: @user)
    @ingredient = @recipe.ingredients.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce")
    @meal_plan = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "dinner")

    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "creates meal plan from custom name when recipe is omitted" do
    assert_difference("MealPlan.count", 1) do
      assert_difference("@trip.recipes.count", 1) do
        post meal_plans_url, params: {
          trip_id: @trip.id,
          meal_plan: {
            recipe_id: "",
            custom_name: "Anreise Snack",
            date: Date.current,
            meal_type: "miscellaneous",
            servings: 2
          }
        }
      end
    end

    created = @trip.meal_plans.order(:created_at).last
    assert_equal "Anreise Snack", created.recipe.name
    assert_equal "miscellaneous", created.meal_type
  end

  test "duplicates meal plan to next day and keeps assignees" do
    @meal_plan.meal_plan_assignees.create!(user: @member)

    assert_difference("@trip.meal_plans.count", 1) do
      post duplicate_meal_plan_url(@meal_plan), params: { trip_id: @trip.id, target_mode: "next_day" }
    end

    duplicated = @trip.meal_plans.order(:created_at).last
    assert_equal @meal_plan.date + 1.day, duplicated.date
    assert_equal [@member.id], duplicated.meal_plan_assignees.pluck(:user_id)
  end

  test "updates assignees for a meal" do
    patch assignees_meal_plan_url(@meal_plan), params: { trip_id: @trip.id, assignee_ids: [@member.id] }

    assert_redirected_to plans_meals_url(trip_id: @trip.id, start_date: @meal_plan.date.beginning_of_week, selected_date: @meal_plan.date)
    assert_equal [@member.id], @meal_plan.reload.meal_plan_assignees.pluck(:user_id)
  end

  test "returns drift preview json" do
    get drift_preview_meal_plan_url(@meal_plan), params: { trip_id: @trip.id }, as: :json
    assert_response :success
    assert_equal false, JSON.parse(response.body)["drifted"]

    @ingredient.update!(quantity: 2)

    get drift_preview_meal_plan_url(@meal_plan), params: { trip_id: @trip.id }, as: :json
    assert_response :success
    assert_equal true, JSON.parse(response.body)["drifted"]
  end

  test "resolve drift accept_new_recipe marks requirements outdated" do
    Shopping::RequirementSynchronizer.new(trip: @trip, user: @user).sync!
    @ingredient.update!(quantity: 2)

    post resolve_drift_meal_plan_url(@meal_plan), params: { trip_id: @trip.id, strategy: "accept_new_recipe" }

    assert_redirected_to plans_meals_url(trip_id: @trip.id, start_date: @meal_plan.date.beginning_of_week, selected_date: @meal_plan.date)
    assert_equal "outdated", @trip.shopping_requirements.first.reload.sync_status
  end

  test "adds meal to shopping plan without leaving meal page" do
    assert_difference("@trip.shopping_requirements.count", 1) do
      post add_to_shopping_plan_meal_plan_url(@meal_plan), params: { trip_id: @trip.id }
    end

    assert_redirected_to plans_meals_url(trip_id: @trip.id, start_date: @meal_plan.date.beginning_of_week, selected_date: @meal_plan.date)
  end

  test "updates meal ingredients inline" do
    patch update_ingredients_meal_plan_url(@meal_plan), params: {
      trip_id: @trip.id,
      recipe: {
        ingredients_attributes: {
          @ingredient.id.to_s => {
            id: @ingredient.id,
            name: "Tomatoes",
            quantity: 2,
            unit: "kg",
            category: "produce"
          }
        }
      }
    }

    assert_redirected_to plans_meals_url(trip_id: @trip.id, start_date: @meal_plan.date.beginning_of_week, selected_date: @meal_plan.date)
    assert_equal 2, @ingredient.reload.quantity.to_i
  end
end
