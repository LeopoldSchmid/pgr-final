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
    select_trip_context(@trip, return_to: plans_meals_path(locale: "en"))

    assert_selector "h1", text: "Meal Plan"
  end

  test "adding a meal to the plan" do
    select_trip_context(@trip, return_to: plans_meals_path(locale: "en"))

    modal = find(:css, "div[id^='add-meal-modal-'][id$='-breakfast']", visible: false, match: :first)
    page.execute_script("arguments[0].classList.remove('hidden')", modal.native)

    within("##{modal[:id]}") do
      select @recipe.name, from: "Recipe"
      fill_in "Notes (optional)", with: "Test meal note"
      click_button "Add Meal"
    end

    assert_text "Meal scheduled successfully"
    assert_text @recipe.name
  end

  test "synchronizing meal plans into the shopping plan" do
    # First add a meal
    MealPlan.create!(
      trip: @trip,
      recipe: @recipe,
      date: Date.today,
      meal_type: "lunch"
    )

    visit plans_shopping_path(locale: "en", trip_id: @trip.id)

    click_on "Synchronize meals"

    assert_text "Requirement pool"

    if @recipe.ingredients.any?
      assert_text @recipe.ingredients.first.name
    end
  end
end
