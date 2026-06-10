require "digest"

class AddFinalizationFieldsToMealPlans < ActiveRecord::Migration[8.0]
  def up
    add_column :meal_plans, :servings, :decimal, precision: 6, scale: 2
    add_column :meal_plans, :recipe_snapshot_signature, :string
    add_column :meal_plans, :drift_status, :string, null: false, default: "in_sync"
    add_column :meal_plans, :series_token, :string

    add_index :meal_plans, :drift_status
    add_index :meal_plans, :series_token

    say_with_time "Backfilling meal plan servings from recipes" do
      MealPlan.reset_column_information
      MealPlan.includes(:recipe).find_each do |meal_plan|
        next if meal_plan.servings.present?

        base_servings = meal_plan.recipe&.servings.to_d
        meal_plan.update_columns(servings: base_servings.positive? ? base_servings : 1)
      end
    end

    say_with_time "Backfilling recipe snapshot signatures" do
      MealPlan.reset_column_information
      MealPlan.includes(recipe: :ingredients).find_each do |meal_plan|
        signature = signature_for(meal_plan)
        meal_plan.update_columns(recipe_snapshot_signature: signature) if signature.present?
      end
    end
  end

  def down
    remove_index :meal_plans, :series_token
    remove_index :meal_plans, :drift_status

    remove_column :meal_plans, :series_token
    remove_column :meal_plans, :drift_status
    remove_column :meal_plans, :recipe_snapshot_signature
    remove_column :meal_plans, :servings
  end

  private

  def signature_for(meal_plan)
    return nil unless meal_plan.recipe

    payload = {
      recipe_id: meal_plan.recipe.id,
      recipe_updated_at: meal_plan.recipe.updated_at,
      ingredients: meal_plan.recipe.ingredients.order(:id).pluck(:id, :name, :quantity, :unit, :updated_at)
    }

    Digest::SHA256.hexdigest(payload.to_json)
  end

  class MealPlan < ActiveRecord::Base
    self.table_name = "meal_plans"
    belongs_to :recipe, class_name: "AddFinalizationFieldsToMealPlans::Recipe", optional: true
  end

  class Recipe < ActiveRecord::Base
    self.table_name = "recipes"
    has_many :ingredients, class_name: "AddFinalizationFieldsToMealPlans::Ingredient", foreign_key: :recipe_id
  end

  class Ingredient < ActiveRecord::Base
    self.table_name = "ingredients"
  end
end
