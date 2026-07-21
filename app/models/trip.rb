class Trip < ApplicationRecord
  belongs_to :user # trip creator
  has_many :journal_entries, dependent: :destroy
  has_many :date_proposals, dependent: :destroy
  has_many :meal_plans, dependent: :destroy
  has_many :trip_members, dependent: :destroy
  has_many :members, through: :trip_members, source: :user
  has_many :trip_people, dependent: :destroy
  has_many :expenses, dependent: :destroy
  has_many :split_groups, dependent: :destroy
  has_many :expense_events, dependent: :destroy
  has_many :client_mutations, dependent: :destroy
  has_many :invitations, dependent: :destroy
  has_many :recipes, dependent: :destroy
  has_many :shopping_lists, dependent: :destroy
  has_many :shopping_requirements, dependent: :destroy
  has_many :shopping_sync_runs, dependent: :destroy
  has_many :trip_attachments, dependent: :destroy
  has_many :discussion_posts, dependent: :destroy

  validates :name, presence: true, length: { maximum: 100 }
  validates :series_name, length: { maximum: 100 }, allow_nil: true

  after_create :create_owner_membership
  after_create :create_owner_trip_person

  scope :in_series, ->(series_name) { where(series_name: series_name) }


  def current_phase
    return "reminisce" if completed?
    return "go" if active?
    "plan"
  end

  def status
    return "completed" if completed?
    return "active" if active?
    "planning"
  end

  def planning?
    !active? && !completed?
  end

  def active?
    return false if start_date.nil? || end_date.nil?
    today = Date.current
    today >= start_date && today <= end_date
  end

  def completed?
    return false if end_date.nil?
    Date.current > end_date
  end

  def favorite_moments
    journal_entries.favorites.by_date
  end

  def journal_summary
    {
      total_entries: journal_entries.count,
      favorite_moments: journal_entries.favorites.count,
      locations_visited: journal_entries.where.not(location: [ nil, "" ]).distinct.count(:location)
    }
  end

  # Membership management methods
  def owners
    trip_members.owners.includes(:user).map(&:user)
  end

  def active_members
    trip_members.active_members.includes(:user).map(&:user)
  end

  def member_role(user)
    trip_members.find_by(user: user)&.role
  end

  def user_can_manage_expenses?(user)
    return true if user == self.user # trip creator always can
    trip_members.find_by(user: user)&.can_manage_expenses? || false
  end

  def add_member(user, role: "member")
    trip_members.create!(user: user, role: role) unless has_member?(user)
    trip_person_for(user)
  end

  def has_member?(user)
    user == self.user || trip_members.exists?(user: user)
  end

  # Expense-related methods
  def total_expenses
    expense_ledger.total_expenses
  end

  def expenses_by_category
    expense_ledger.expenses_by_category
  end

  def user_balance(user)
    return 0 unless has_member?(user)

    trip_person = trip_people.find_by(user: user)
    return legacy_user_balance(user) unless trip_person

    expense_ledger.balance_for(trip_person)
  end

  def settlement_suggestions
    expense_ledger.settlement_suggestions
  end

  def trip_person_for(user)
    TripPerson.find_or_create_for_user!(trip: self, user: user)
  end

  def ensure_expense_people!
    ([ user ] + active_members).compact.uniq.each { |member| trip_person_for(member) }
  end

  def expense_ledger
    Expenses::Ledger.new(self)
  end

  private

  def create_owner_membership
    add_member(user, role: "owner")
  end

  def create_owner_trip_person
    trip_person_for(user)
  end

  def legacy_user_balance(user)
    amount_paid = expenses.where(payer: user).sum(:amount)
    amount_owed = ExpenseParticipant
      .joins(:expense)
      .where(expenses: { trip: self }, user: user)
      .sum(:amount_owed)

    amount_paid - amount_owed
  end
end
