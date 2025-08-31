class DateProposalVote < ApplicationRecord
  belongs_to :date_proposal
  belongs_to :user

  validates :vote_type, presence: true, inclusion: { in: %w[yes no maybe] }
  validates :user_id, uniqueness: { scope: :date_proposal_id, message: "can only vote once per proposal" }

  scope :yes_votes, -> { where(vote_type: 'yes') }
  scope :no_votes, -> { where(vote_type: 'no') }
  scope :maybe_votes, -> { where(vote_type: 'maybe') }
end
