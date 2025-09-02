class DiscussionReply < ApplicationRecord
  belongs_to :discussion_post
  belongs_to :user
  belongs_to :parent, class_name: 'DiscussionReply', optional: true
  has_many :children, class_name: 'DiscussionReply', foreign_key: 'parent_id', dependent: :destroy
  has_many :discussion_votes, as: :votable, dependent: :destroy
  
  validates :content, presence: true
  validate :no_deep_nesting
  
  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }
  scope :by_votes, -> { order(upvotes_count: :desc, created_at: :asc) }
  scope :top_level, -> { where(parent_id: nil) }
  
  def net_votes
    discussion_votes.upvotes.count - discussion_votes.downvotes.count
  end
  
  def top_level?
    parent_id.nil?
  end
  
  def second_level?
    parent_id.present? && parent.parent_id.nil?
  end
  
  def depth
    parent_id.nil? ? 0 : 1
  end
  
  def user_vote(user)
    discussion_votes.find_by(user: user)&.vote_type
  end
  
  def user_voted?(user, vote_type)
    discussion_votes.exists?(user: user, vote_type: vote_type)
  end
  
  private
  
  def no_deep_nesting
    if parent_id.present? && parent&.parent_id.present?
      errors.add(:parent, "can't be more than 2 levels deep")
    end
  end
end