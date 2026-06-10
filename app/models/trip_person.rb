class TripPerson < ApplicationRecord
  STATUSES = %w[active invited placeholder archived].freeze

  belongs_to :trip
  belongs_to :user, optional: true

  has_many :paid_expenses, class_name: "Expense", foreign_key: :payer_trip_person_id, dependent: :restrict_with_error
  has_many :expense_splits, dependent: :restrict_with_error
  has_many :split_group_memberships, dependent: :destroy
  has_many :split_groups, through: :split_group_memberships

  normalizes :email, with: ->(email) { email.to_s.strip.downcase.presence }

  validates :display_name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: STATUSES }
  validates :user_id, uniqueness: { scope: :trip_id }, allow_nil: true

  before_validation :set_display_name_from_user, if: -> { display_name.blank? && user.present? }
  before_validation :set_email_from_user, if: -> { email.blank? && user.present? }

  scope :active_ledger_people, -> { where(status: %w[active invited placeholder]) }
  scope :linked, -> { where.not(user_id: nil) }

  def self.find_or_create_for_user!(trip:, user:, status: "active")
    find_or_create_by!(trip: trip, user: user) do |trip_person|
      trip_person.display_name = user.email_address.to_s.split("@").first
      trip_person.email = user.email_address
      trip_person.status = status
    end
  end

  def linked?
    user_id.present?
  end

  def email_address
    email.presence || user&.email_address || display_name
  end

  def archived?
    status == "archived"
  end

  def link_user!(linked_user)
    self.user = linked_user
    self.email ||= linked_user.email_address
    self.status = "active" if status == "invited" || status == "placeholder"
    save!
  end

  private

  def set_display_name_from_user
    self.display_name = user.email_address.to_s.split("@").first
  end

  def set_email_from_user
    self.email = user.email_address
  end
end
