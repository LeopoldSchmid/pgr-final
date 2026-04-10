class ShoppingSyncRun < ApplicationRecord
  belongs_to :trip
  belongs_to :user

  validates :started_at, presence: true
  validates :undo_token, presence: true, uniqueness: true

  before_validation :set_defaults, on: :create

  scope :recent_first, -> { order(created_at: :desc) }

  def finished?
    finished_at.present?
  end

  private

  def set_defaults
    self.started_at ||= Time.current
    self.undo_token ||= SecureRandom.hex(16)
  end
end
