class ExpenseSplit < ApplicationRecord
  METHODS = %w[equal exact shares percentage].freeze

  belongs_to :expense
  belongs_to :trip_person

  validates :amount_owed, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :split_method, inclusion: { in: METHODS }
  validates :trip_person_id, uniqueness: { scope: :expense_id }
  validate :trip_person_belongs_to_expense_trip

  private

  def trip_person_belongs_to_expense_trip
    return if expense.blank? || trip_person.blank?

    if trip_person.trip_id != expense.trip_id
      errors.add(:trip_person, "must belong to the expense trip")
    end
  end
end
