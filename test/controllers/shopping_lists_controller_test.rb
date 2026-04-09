require "test_helper"

class ShoppingListsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "shopping_lists_test@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "Shopping Test Trip",
      start_date: Date.current,
      end_date: Date.current + 2.days
    )

    @recipe = Recipe.create!(
      name: "Tomato Pasta",
      description: "Simple pasta",
      servings: 4,
      trip: @trip,
      user: @user
    )

    @recipe.ingredients.create!(
      name: "Tomatoes",
      quantity: 4,
      unit: "pieces",
      category: "produce"
    )

    @shopping_list = @trip.shopping_lists.create!(
      name: "Trip Shopping",
      status: "draft"
    )

    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "generate_from_meal_plan creates shopping items from planned meals" do
    MealPlan.create!(
      trip: @trip,
      recipe: @recipe,
      date: Date.current,
      meal_type: "dinner"
    )

    post generate_from_meal_plan_trip_shopping_list_url(@trip, @shopping_list), params: { people_count: 2 }

    assert_redirected_to trip_shopping_list_url(@trip, @shopping_list)
    assert_equal "Generated shopping list from 1 planned meal!", flash[:notice]

    @shopping_list.reload
    assert_equal "active", @shopping_list.status
    assert_equal 1, @shopping_list.shopping_items.count

    item = @shopping_list.shopping_items.first
    assert_equal "Tomatoes", item.name
    assert_equal 2.0, item.quantity
    assert_equal "Recipe", item.source_type
  end

  test "generate_from_meal_plan includes every ingredient from a planned recipe" do
    @recipe.ingredients.create!(
      name: "Salt",
      quantity: 1,
      unit: "tsp",
      category: "spices"
    )

    MealPlan.create!(
      trip: @trip,
      recipe: @recipe,
      date: Date.current,
      meal_type: "dinner"
    )

    post generate_from_meal_plan_trip_shopping_list_url(@trip, @shopping_list), params: { people_count: 2 }

    assert_redirected_to trip_shopping_list_url(@trip, @shopping_list)

    items = @shopping_list.reload.shopping_items.order(:name).pluck(:name, :quantity, :unit, :category)
    assert_equal [
      [ "Salt", 0.5, "tsp", "spices" ],
      [ "Tomatoes", 2.0, "pieces", "produce" ]
    ], items
  end

  test "generate_from_meal_plan redirects back to meal planning when no meals exist" do
    post generate_from_meal_plan_trip_shopping_list_url(@trip, @shopping_list)

    assert_redirected_to plans_meals_url
    assert_equal "Please plan some meals first.", flash[:alert]
    assert_equal 0, @shopping_list.shopping_items.count
  end
end
