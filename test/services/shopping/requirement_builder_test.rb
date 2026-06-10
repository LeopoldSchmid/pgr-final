require "test_helper"

module Shopping
  class RequirementBuilderTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(email_address: "shopping_requirement_builder@example.com", password: "password123", locale: "en")
      @trip = Trip.create!(user: @user, name: "Builder Trip", start_date: Date.current, end_date: Date.current + 2.days)
    end

    test "builds meal-plan-backed requirements using standard food item units" do
      tomatoes = FoodItem.create!(name: "Tomatoes", standard_unit: "kg", category: "produce", unit_type: "weight")

      recipe = Recipe.create!(name: "Pasta", description: "Dinner", servings: 2, trip: @trip, user: @user)
      recipe.ingredients.create!(name: "Tomatoes", quantity: 500, unit: "g", category: "produce", food_item: tomatoes)
      meal_plan = MealPlan.create!(trip: @trip, recipe: recipe, date: Date.current, meal_type: "dinner")

      entries = RequirementBuilder.new(@trip).call

      assert_equal 1, entries.length
      entry = entries.first
      assert_equal [ meal_plan.id, "food_item", tomatoes.id, "kg" ].join(":"), entry.matching_key
      assert_equal "Tomatoes", entry.attributes[:name]
      assert_equal 0.5, entry.attributes[:quantity]
      assert_equal "kg", entry.attributes[:unit]
      assert_equal "meal_plan", entry.attributes[:source_type]
      assert_equal "in_sync", entry.attributes[:sync_status]
      assert entry.attributes[:source_signature].present?
    end

    test "scales ingredient quantities based on meal servings" do
      tomatoes = FoodItem.create!(name: "Tomatoes", standard_unit: "kg", category: "produce", unit_type: "weight")
      recipe = Recipe.create!(name: "Soup", description: "Lunch", servings: 4, trip: @trip, user: @user)
      recipe.ingredients.create!(name: "Tomatoes", quantity: 2, unit: "kg", category: "produce", food_item: tomatoes)
      MealPlan.create!(trip: @trip, recipe: recipe, date: Date.current, meal_type: "lunch", servings: 2)

      entry = RequirementBuilder.new(@trip).call.first

      assert_equal 1.0, entry.attributes[:quantity].to_f
    end
  end
end
