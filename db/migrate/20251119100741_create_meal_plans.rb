class CreateMealPlans < ActiveRecord::Migration[8.1]
  def change
    create_table :meal_plans do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :recipe, null: false, foreign_key: true
      t.date :date
      t.string :meal_type
      t.text :description

      t.timestamps
    end
  end
end
