class TripAttachment < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  has_one_attached :file

  validates :name, :file, presence: true
end
