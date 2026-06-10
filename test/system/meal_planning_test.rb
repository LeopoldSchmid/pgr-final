require "application_system_test_case"

class MealPlanningTest < ApplicationSystemTestCase
  setup do
    @user = User.create!(
      email_address: "meal_test@example.com",
      password: "password",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "Test Trip to Paris",
      description: "A wonderful trip to Paris",
      start_date: Date.today,
      end_date: Date.today + 7.days
    )

    @recipe = Recipe.create!(
      name: "Pasta Carbonara",
      description: "Classic Italian pasta dish",
      servings: 4,
      trip: @trip,
      user: @user
    )
    @recipe.ingredients.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce")

    # Create a shopping list for the trip
    @shopping_list = @trip.shopping_lists.create!(
      name: "Groceries",
      status: "draft"
    )

    # UI Login
    visit new_session_path(locale: "en")
    fill_in "Email", with: @user.email_address
    fill_in "Password", with: "password"
    click_on "Sign in"

    # Wait for login to complete
    assert_text "Welcome back"
  end

  def select_trip_context(trip, return_to:)
    visit select_trip_path(locale: "en", return_to: return_to)

    within(:xpath, "//div[contains(@class, 'rounded-lg')][.//h3[contains(text(), '#{trip.name}')]]") do
      click_on "Select"
    end
  end

  test "visiting the meal calendar" do
    week_start = Date.today.beginning_of_week
    select_trip_context(@trip, return_to: plans_meals_path(locale: "en", start_date: week_start, selected_date: week_start))

    assert_selector "#meal_type_breakfast"
  end

  test "adding a meal to the plan" do
    week_start = Date.today.beginning_of_week
    select_trip_context(@trip, return_to: plans_meals_path(locale: "en", start_date: week_start, selected_date: week_start))

    within("#meal_type_breakfast") do
      find("summary", text: "+ Meal").click
      select @recipe.name, from: "meal_plan_recipe_id_breakfast"
      fill_in "meal_plan_description_breakfast", with: "Test meal note"
      click_button "Add meal"
    end

    assert_text "Meal scheduled successfully"
    assert_text @recipe.name
  end

  test "synchronizing meal plans into the shopping plan" do
    week_start = Date.today.beginning_of_week

    # First add a meal
    MealPlan.create!(
      trip: @trip,
      recipe: @recipe,
      date: week_start,
      meal_type: "lunch"
    )

    select_trip_context(@trip, return_to: plans_meals_path(locale: "en", start_date: week_start, selected_date: week_start))

    form = find("form[action*='add_to_shopping_plan']", match: :first, visible: :all)
    page.execute_script("arguments[0].requestSubmit()", form)

    assert_text "Shopping plan updated."
  end
end
