class DateProposal < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date, message: "cannot be before start date" }
end
