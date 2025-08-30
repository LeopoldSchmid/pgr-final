class ExpenseParticipant < ApplicationRecord
  belongs_to :expense
  belongs_to :user
  
  validates :amount_owed, presence: true, numericality: { greater_than: 0 }
  validates :user_id, uniqueness: { scope: :expense_id, message: 'is already a participant in this expense' }
  
  scope :for_user, ->(user) { where(user: user) }
  
  def formatted_amount_owed(with_currency: true)
    formatted = "%.2f" % amount_owed
    if with_currency && expense&.currency
      "#{formatted} #{expense.currency}"
    else
      formatted
    end
  end
end
