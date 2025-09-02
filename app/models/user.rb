class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :trips, dependent: :destroy # trips user created
  has_many :trip_members, dependent: :destroy
  has_many :member_trips, through: :trip_members, source: :trip # trips user is member of
  has_many :paid_expenses, class_name: "Expense", foreign_key: "payer_id", dependent: :destroy
  has_many :expense_participants, dependent: :destroy
  has_many :participated_expenses, through: :expense_participants, source: :expense
  has_many :journal_entries, dependent: :destroy
  has_many :user_availabilities, dependent: :destroy
  has_many :date_proposal_votes, dependent: :destroy
  has_many :trip_attachments, dependent: :destroy

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  # Locale preferences
  validates :locale, inclusion: { in: I18n.available_locales.map(&:to_s), message: :invalid }

  # Avatar preferences
  AVATAR_OPTIONS = %w[traveler adventurer photographer foodie explorer beachgoer hiker cultural nature wanderer].freeze
  validates :avatar, inclusion: { in: AVATAR_OPTIONS, allow_blank: true }

  # Returns user's preferred locale or app default
  def preferred_locale
    locale.present? ? locale.to_sym : I18n.default_locale
  end

  # Sets user locale preference
  def locale=(new_locale)
    super(new_locale.to_s) if new_locale.present?
  end

  def all_trips
    Trip.where(id: (trips.pluck(:id) + member_trips.pluck(:id)).uniq)
  end
end
