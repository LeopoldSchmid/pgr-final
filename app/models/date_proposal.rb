class DateProposal < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  has_many :date_proposal_votes, dependent: :destroy

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date, message: "cannot be before start date" }

  def vote_summary
    {
      yes: date_proposal_votes.yes_votes.count,
      no: date_proposal_votes.no_votes.count,
      maybe: date_proposal_votes.maybe_votes.count,
      total: date_proposal_votes.count
    }
  end

  def user_vote(user)
    date_proposal_votes.find_by(user: user)&.vote_type
  end

  def duration_in_days
    (end_date - start_date).to_i + 1
  end

  def conflicts_with_availability?(user_availability_periods = [])
    user_availability_periods.any? do |period|
      date_ranges_overlap?(start_date, end_date, period.start_date, period.end_date)
    end
  end

  private

  def date_ranges_overlap?(start1, end1, start2, end2)
    start1 <= end2 && end1 >= start2
  end
end
