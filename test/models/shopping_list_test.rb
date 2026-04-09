require "test_helper"

class ShoppingListTest < ActiveSupport::TestCase
  def setup
    @user = User.create!(
      email_address: "shopping_list_model_test@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "Shopping Model Trip",
      start_date: Date.current,
      end_date: Date.current + 3.days
    )

    @shopping_list = @trip.shopping_lists.create!(
      name: "Trip Shopping",
      status: "draft"
    )
  end

  test "generate_from_meal_plan keeps multiple manual ingredients from one recipe" do
    recipe = Recipe.create!(
      name: "Pasta",
      description: "Simple pasta",
      servings: 2,
      trip: @trip,
      user: @user
    )

    recipe.ingredients.create!(
      name: "Tomatoes",
      quantity: 2,
      unit: "pieces",
      category: "produce"
    )

    recipe.ingredients.create!(
      name: "Salt",
      quantity: 1,
      unit: "tsp",
      category: "spices"
    )

    MealPlan.create!(
      trip: @trip,
      recipe: recipe,
      date: Date.current,
      meal_type: "dinner"
    )

    @shopping_list.generate_from_meal_plan(@trip.meal_plans.includes(:recipe), 2)

    items = @shopping_list.shopping_items.order(:name).pluck(:name, :quantity, :unit, :category)

    assert_equal [
      [ "Salt", 1.0, "tsp", "spices" ],
      [ "Tomatoes", 2.0, "pieces", "produce" ]
    ], items
  end

  test "generate_from_meal_plan scales quantities by people count" do
    recipe = Recipe.create!(
      name: "Tomato Soup",
      description: "Scaled recipe",
      servings: 4,
      trip: @trip,
      user: @user
    )

    recipe.ingredients.create!(
      name: "Tomatoes",
      quantity: 4,
      unit: "pieces",
      category: "produce"
    )

    MealPlan.create!(
      trip: @trip,
      recipe: recipe,
      date: Date.current,
      meal_type: "lunch"
    )

    @shopping_list.generate_from_meal_plan(@trip.meal_plans.includes(:recipe), 2)

    item = @shopping_list.shopping_items.find_by!(name: "Tomatoes")
    assert_equal 2.0, item.quantity
  end

  test "generate_from_meal_plan groups compatible food items across recipes" do
    tomatoes = FoodItem.create!(
      name: "Tomatoes",
      standard_unit: "g",
      category: "produce",
      unit_type: "weight"
    )

    recipe_one = Recipe.create!(
      name: "Sauce",
      description: "Sauce recipe",
      servings: 2,
      trip: @trip,
      user: @user
    )

    recipe_one.ingredients.create!(
      name: "Tomatoes",
      quantity: 500,
      unit: "g",
      category: "produce",
      food_item: tomatoes
    )

    recipe_two = Recipe.create!(
      name: "Salad",
      description: "Salad recipe",
      servings: 2,
      trip: @trip,
      user: @user
    )

    recipe_two.ingredients.create!(
      name: "Tomatoes",
      quantity: 1,
      unit: "kg",
      category: "produce",
      food_item: tomatoes
    )

    MealPlan.create!(
      trip: @trip,
      recipe: recipe_one,
      date: Date.current,
      meal_type: "lunch"
    )

    MealPlan.create!(
      trip: @trip,
      recipe: recipe_two,
      date: Date.current + 1.day,
      meal_type: "dinner"
    )

    @shopping_list.generate_from_meal_plan(@trip.meal_plans.includes(:recipe))

    items = @shopping_list.shopping_items.order(:name).pluck(:name, :quantity, :unit, :category)

    assert_equal [
      [ "Tomatoes", 1500.0, "g", "produce" ]
    ], items
  end
end
