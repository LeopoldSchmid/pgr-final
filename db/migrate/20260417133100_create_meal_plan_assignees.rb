class CreateMealPlanAssignees < ActiveRecord::Migration[8.0]
  def change
    create_table :meal_plan_assignees do |t|
      t.references :meal_plan, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :meal_plan_assignees, [:meal_plan_id, :user_id], unique: true
  end
end
