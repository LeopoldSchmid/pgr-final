class MealPlan < ApplicationRecord
  belongs_to :trip
  belongs_to :recipe
  has_many :shopping_requirements, dependent: :nullify

  validates :date, presence: true
  validates :meal_type, presence: true, inclusion: { in: %w[breakfast lunch dinner snack] }

  scope :ordered, -> { order(date: :asc, meal_type: :asc) }
  scope :for_date, ->(date) { where(date: date) }
end
