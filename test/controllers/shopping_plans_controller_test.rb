require "test_helper"

class ShoppingPlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(email_address: "shopping_plans_controller@example.com", password: "password123", locale: "en")
    @trip = Trip.create!(user: @user, name: "Shopping Plan Trip", start_date: Date.current, end_date: Date.current + 3.days)
    @list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
    @beer = FoodItem.create!(name: "Beer", standard_unit: "l", category: "other", unit_type: "volume")

    @recipe = Recipe.create!(name: "Pasta", description: "Dinner", servings: 2, trip: @trip, user: @user)
    @ingredient = @recipe.ingredients.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce")
    @meal_plan = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "dinner")

    post session_url, params: { email_address: @user.email_address, password: "password123" }
  end

  test "shows shopping plan" do
    get plans_shopping_url, params: { trip_id: @trip.id }

    assert_response :success
    assert_match "Shopping Plan", response.body
  end
  test "shows shopping plan grouped by source" do
    @trip.shopping_requirements.create!(name: "Eggs", quantity: 6, unit: "pieces", category: "other", source_type: "manual", sync_status: "manual", source_label: "Spaghetti Carbonara")

    get plans_shopping_url, params: { trip_id: @trip.id, group: "source" }

    assert_response :success
    assert_match "By source", response.body
    assert_match "Spaghetti Carbonara", response.body
  end

  test "auto-creates default shopping list when opening shopping plan without lists" do
    @trip.shopping_lists.destroy_all

    assert_difference("@trip.shopping_lists.count", 1) do
      get plans_shopping_url, params: { trip_id: @trip.id }
    end

    assert_response :success
    assert_equal "Trip Shopping List", @trip.shopping_lists.order(:created_at).last.name
  end


  test "sync creates shopping requirements" do
    assert_difference("@trip.shopping_requirements.count", 1) do
      post plans_shopping_sync_url, params: { trip_id: @trip.id }
    end

    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
    assert_equal "meal_plan", @trip.shopping_requirements.last.source_type
  end

  test "creates manual requirement" do
    assert_difference("@trip.shopping_requirements.manual_only.count", 1) do
      post plans_shopping_manual_requirement_url, params: {
        trip_id: @trip.id,
        shopping_requirement: {
          name: "Beer",
          quantity: 12,
          unit: "l",
          category: "other"
        }
      }
    end

    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
  end

  test "creates manual requirement from food item defaults" do
    assert_difference("@trip.shopping_requirements.manual_only.count", 1) do
      post plans_shopping_manual_requirement_url, params: {
        trip_id: @trip.id,
        shopping_requirement: {
          food_item_id: @beer.id,
          name: "",
          quantity: 12,
          unit: "",
          category: ""
        }
      }
    end

    requirement = @trip.shopping_requirements.order(:created_at).last
    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
    assert_equal "Beer", requirement.name
    assert_equal "l", requirement.unit
    assert_equal "other", requirement.category
    assert_equal @beer, requirement.food_item
  end

  test "rapidly creates manual requirement using defaults when quantity is omitted" do
    assert_difference("@trip.shopping_requirements.manual_only.count", 1) do
      post plans_shopping_manual_requirement_url, params: {
        trip_id: @trip.id,
        shopping_requirement: {
          name: "Rapid Item",
          quantity: "",
          unit: "",
          category: ""
        }
      }
    end

    requirement = @trip.shopping_requirements.order(:created_at).last
    assert_equal "Rapid Item", requirement.name
    assert_equal 1.0, requirement.quantity
    assert_equal "pieces", requirement.unit
    assert_equal "other", requirement.category
  end

  test "assigns requirement to shopping list" do
    requirement = Shopping::RequirementSynchronizer.new(trip: @trip, user: @user).sync!.created.first

    assert_difference("requirement.shopping_list_assignments.count", 1) do
      post plans_shopping_requirement_assignments_url(requirement_id: requirement.id), params: {
        trip_id: @trip.id,
        shopping_list_id: @list.id,
        quantity: 1,
        unit: "kg"
      }
    end

    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
    assert_equal 1, requirement.reload.assigned_quantity
  end

  test "requires shopping list selection for assignment" do
    requirement = Shopping::RequirementSynchronizer.new(trip: @trip, user: @user).sync!.created.first

    assert_no_difference("requirement.shopping_list_assignments.count") do
      post plans_shopping_requirement_assignments_url(requirement_id: requirement.id), params: {
        trip_id: @trip.id,
        shopping_list_id: "",
        quantity: 1,
        unit: "kg"
      }
    end

    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
  end

  test "deletes selected requirements" do
    manual_one = @trip.shopping_requirements.create!(name: "Beer", quantity: 2, unit: "l", category: "other", source_type: "manual", sync_status: "manual")
    manual_two = @trip.shopping_requirements.create!(name: "Bread", quantity: 1, unit: "pieces", category: "pantry", source_type: "manual", sync_status: "manual")

    assert_difference("@trip.shopping_requirements.count", -2) do
      post plans_shopping_delete_selected_url, params: { trip_id: @trip.id, requirement_ids: [manual_one.id, manual_two.id] }
    end

    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
  end
end
