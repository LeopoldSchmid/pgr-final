class TripAttachment < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  has_one_attached :file

  validates :name, presence: true
  validate :file_presence
  validate :file_size_validation
  validate :file_content_type_validation

  private

  def file_presence
    errors.add(:file, 'must be attached') unless file.attached?
  end

  def file_size_validation
    return unless file.attached?

    if file.blob.byte_size > 10.megabytes
      errors.add(:file, 'must be less than 10MB')
    end
  end

  def file_content_type_validation
    return unless file.attached?

    acceptable_types = %w[
      image/jpeg image/jpg image/png image/gif image/webp 
      application/pdf application/msword application/vnd.openxmlformats-officedocument.wordprocessingml.document
      application/vnd.ms-excel application/vnd.openxmlformats-officedocument.spreadsheetml.sheet
      text/plain text/csv
    ]

    unless acceptable_types.include?(file.blob.content_type)
      errors.add(:file, 'must be a valid file type (images, PDFs, documents, or text files)')
    end
  end
end
