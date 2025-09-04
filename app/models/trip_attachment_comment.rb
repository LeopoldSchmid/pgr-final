class TripAttachmentComment < ApplicationRecord
  belongs_to :user
  belongs_to :trip_attachment

  validates :content, presence: true, length: { maximum: 500 }

  scope :recent, -> { order(created_at: :desc) }
  scope :oldest_first, -> { order(created_at: :asc) }

  def trip
    trip_attachment.trip
  end
end