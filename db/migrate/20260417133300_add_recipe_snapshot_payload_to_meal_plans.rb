class AddRecipeSnapshotPayloadToMealPlans < ActiveRecord::Migration[8.0]
  def change
    add_column :meal_plans, :recipe_snapshot_payload, :json
  end
end
