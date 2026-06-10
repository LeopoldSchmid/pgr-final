class MealPlanAssignee < ApplicationRecord
  belongs_to :meal_plan
  belongs_to :user

  validates :user_id, uniqueness: { scope: :meal_plan_id }
end
