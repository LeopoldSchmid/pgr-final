class UserAvailability < ApplicationRecord
  belongs_to :user

  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :availability_type, presence: true, inclusion: { in: %w[unavailable busy preferred] }
  validates :end_date, comparison: { greater_than_or_equal_to: :start_date, message: "cannot be before start date" }

  scope :unavailable, -> { where(availability_type: 'unavailable') }
  scope :busy, -> { where(availability_type: 'busy') }
  scope :preferred, -> { where(availability_type: 'preferred') }
  scope :in_date_range, ->(start_date, end_date) { where('start_date <= ? AND end_date >= ?', end_date, start_date) }

  def duration_in_days
    (end_date - start_date).to_i + 1
  end

  def overlaps_with?(other_start_date, other_end_date)
    start_date <= other_end_date && end_date >= other_start_date
  end

  def display_title
    title.present? ? title : availability_type.humanize
  end
end
