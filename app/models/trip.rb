class Trip < ApplicationRecord
  belongs_to :user # trip creator
  has_many :journal_entries, dependent: :destroy
  has_many :trip_members, dependent: :destroy
  has_many :members, through: :trip_members, source: :user
  has_many :expenses, dependent: :destroy
  has_many :invitations, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: %w[planning active completed] }
  
  after_create :create_owner_membership
  
  scope :planning, -> { where(status: 'planning') }
  scope :active, -> { where(status: 'active') }
  scope :completed, -> { where(status: 'completed') }
  
  def current_phase
    return 'reminisce' if completed?
    return 'go' if active? && (start_date.nil? || start_date <= Date.current)
    'plan'
  end
  
  def planning?
    status == 'planning'
  end
  
  def active?
    status == 'active'
  end
  
  def completed?
    status == 'completed'
  end
  
  def favorite_moments
    journal_entries.favorites.by_date
  end
  
  def journal_summary
    {
      total_entries: journal_entries.count,
      favorite_moments: journal_entries.favorites.count,
      locations_visited: journal_entries.where.not(location: [nil, '']).distinct.count(:location)
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
  
  def add_member(user, role: 'member')
    trip_members.create!(user: user, role: role) unless has_member?(user)
  end
  
  def has_member?(user)
    user == self.user || trip_members.exists?(user: user)
  end
  
  # Expense-related methods
  def total_expenses
    expenses.sum(:amount)
  end
  
  def expenses_by_category
    expenses.group(:category).sum(:amount)
  end
  
  def user_balance(user)
    return 0 unless has_member?(user)
    
    amount_paid = expenses.where(payer: user).sum(:amount)
    amount_owed = ExpenseParticipant
      .joins(:expense)
      .where(expenses: { trip: self }, user: user)
      .sum(:amount_owed)
    
    amount_paid - amount_owed
  end
  
  def settlement_suggestions
    # Calculate net balances for all members
    balances = {}
    all_trip_users = [user] + active_members
    
    all_trip_users.each do |member|
      balances[member] = user_balance(member)
    end
    
    # Generate settlement suggestions (simplified version)
    suggestions = []
    debtors = balances.select { |_, balance| balance < 0 }
    creditors = balances.select { |_, balance| balance > 0 }
    
    debtors.each do |debtor_user, debt_amount|
      debt_remaining = debt_amount.abs
      
      creditors.each do |creditor_user, credit_amount|
        next if credit_amount <= 0 || debt_remaining <= 0
        
        settlement_amount = [debt_remaining, credit_amount].min
        suggestions << {
          from: debtor_user,
          to: creditor_user,
          amount: settlement_amount,
          currency: 'EUR' # TODO: handle multiple currencies
        }
        
        debt_remaining -= settlement_amount
        creditors[creditor_user] -= settlement_amount
        break if debt_remaining <= 0
      end
    end
    
    suggestions
  end
  
  private
  
  def create_owner_membership
    add_member(user, role: 'owner')
  end
end
