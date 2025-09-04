class TripAttachment < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  has_many :trip_attachment_comments, dependent: :destroy
  has_many :discussion_votes, as: :votable, dependent: :destroy

  has_many_attached :files

  validates :name, presence: true
  validate :files_presence
  validate :files_size_validation
  validate :files_content_type_validation
  validate :files_count_validation

  # Backward compatibility method
  def file
    files.first
  end

  # Instagram-like functionality
  def likes_count
    discussion_votes.upvotes.count
  end

  def comments_count
    trip_attachment_comments.count
  end

  def user_liked?(user)
    discussion_votes.exists?(user: user, vote_type: 'upvote')
  end

  def user_vote(user)
    discussion_votes.find_by(user: user)&.vote_type
  end

  private

  def files_presence
    errors.add(:files, 'must be attached') unless files.attached?
  end

  def files_size_validation
    return unless files.attached?

    files.each_with_index do |file, index|
      if file.blob.byte_size > 10.megabytes
        errors.add(:files, "file #{index + 1} must be less than 10MB")
      end
    end

    # Total size validation (50MB for all files combined)
    total_size = files.sum { |file| file.blob.byte_size }
    if total_size > 50.megabytes
      errors.add(:files, 'total size must be less than 50MB')
    end
  end

  def files_content_type_validation
    return unless files.attached?

    acceptable_types = %w[
      image/jpeg image/jpg image/png image/gif image/webp 
      application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      text/plain text/csv
    ]

    files.each_with_index do |file, index|
      unless acceptable_types.include?(file.blob.content_type)
        errors.add(:files, "file #{index + 1} must be a valid file type (images, PDFs, documents, or text files)")
      end
    end
  end

  def files_count_validation
    return unless files.attached?

    if files.count > 10
      errors.add(:files, 'cannot upload more than 10 files at once')
    end
  end
end
