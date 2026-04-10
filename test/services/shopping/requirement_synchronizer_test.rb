require "test_helper"

module Shopping
  class RequirementSynchronizerTest < ActiveSupport::TestCase
    def setup
      @user = User.create!(email_address: "shopping_requirement_sync@example.com", password: "password123", locale: "en")
      @trip = Trip.create!(user: @user, name: "Sync Trip", start_date: Date.current, end_date: Date.current + 2.days)
      @recipe = Recipe.create!(name: "Bruschetta", description: "Dinner", servings: 2, trip: @trip, user: @user)
      @ingredient = @recipe.ingredients.create!(name: "Tomatoes", quantity: 1, unit: "kg", category: "produce")
      @meal_plan = MealPlan.create!(trip: @trip, recipe: @recipe, date: Date.current, meal_type: "dinner")
    end

    test "sync creates requirements from meal plans" do
      result = RequirementSynchronizer.new(trip: @trip, user: @user).sync!

      assert_equal 1, result.created.size
      requirement = @trip.shopping_requirements.first
      assert_equal "Tomatoes", requirement.name
      assert_equal "meal_plan", requirement.source_type
      assert_equal "in_sync", requirement.sync_status
      assert result.sync_run.finished?
    end

    test "mark_outdated flags changed requirements before sync" do
      RequirementSynchronizer.new(trip: @trip, user: @user).sync!
      @ingredient.update!(quantity: 2)

      comparison = RequirementSynchronizer.new(trip: @trip, user: @user).mark_outdated!

      assert_equal 1, comparison[:changed].size
      assert_equal "outdated", @trip.shopping_requirements.first.reload.sync_status
    end

    test "sync updates changed requirements and detaches removed ones with assignments" do
      RequirementSynchronizer.new(trip: @trip, user: @user).sync!
      requirement = @trip.shopping_requirements.first
      shopping_list = @trip.shopping_lists.create!(name: "Aldi", status: "draft")
      requirement.shopping_list_assignments.create!(shopping_list: shopping_list, planned_quantity: 1, purchased_quantity: 0, unit: "kg")

      @recipe.ingredients.destroy_all

      result = RequirementSynchronizer.new(trip: @trip, user: @user).sync!

      assert_equal 1, result.removed.size
      assert_equal "detached", requirement.reload.sync_status
    end

    test "undo restores previous requirement attributes" do
      RequirementSynchronizer.new(trip: @trip, user: @user).sync!
      requirement = @trip.shopping_requirements.first
      previous_signature = requirement.last_synced_signature

      @ingredient.update!(quantity: 2)
      result = RequirementSynchronizer.new(trip: @trip, user: @user).sync!

      assert_equal 2, requirement.reload.quantity.to_f
      Shopping::UndoSync.new(result.sync_run).call

      assert_equal 1, requirement.reload.quantity.to_f
      assert_equal previous_signature, requirement.last_synced_signature
    end
  end
end
