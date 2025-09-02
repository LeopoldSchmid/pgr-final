class DiscussionPost < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  has_many :discussion_replies, dependent: :destroy
  has_many :discussion_votes, as: :votable, dependent: :destroy
  
  validates :title, presence: true, length: { maximum: 200 }
  validates :content, presence: true
  
  scope :recent, -> { order(created_at: :desc) }
  scope :by_votes, -> { order(upvotes_count: :desc, created_at: :desc) }
  
  def net_votes
    discussion_votes.upvotes.count - discussion_votes.downvotes.count
  end
  
  def reply_count
    discussion_replies.count
  end
  
  def user_vote(user)
    discussion_votes.find_by(user: user)&.vote_type
  end
  
  def user_voted?(user, vote_type)
    discussion_votes.exists?(user: user, vote_type: vote_type)
  end
end