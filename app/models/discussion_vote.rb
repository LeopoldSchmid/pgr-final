class DiscussionVote < ApplicationRecord
  belongs_to :user
  belongs_to :votable, polymorphic: true
  
  validates :vote_type, inclusion: { in: %w[upvote downvote] }
  validates :user_id, uniqueness: { scope: [:votable_type, :votable_id] }
  
  scope :upvotes, -> { where(vote_type: 'upvote') }
  scope :downvotes, -> { where(vote_type: 'downvote') }
end
