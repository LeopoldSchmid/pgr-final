class Expense < ApplicationRecord
  belongs_to :trip
  belongs_to :payer, class_name: 'User'
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user
  has_one_attached :receipt
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true, length: { maximum: 200 }
  validates :category, inclusion: { in: %w[food accommodation transport activities shopping other] }
  validates :currency, presence: true, length: { is: 3 }
  validates :expense_date, presence: true
  validates :latitude, presence: true, if: :longitude?
  validates :longitude, presence: true, if: :latitude?
  
  scope :by_date, -> { order(:expense_date, :created_at) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_payer, ->(user) { where(payer: user) }
  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }
  
  before_validation :set_expense_date, on: :create
  
  def coordinates
    return nil unless has_location?
    [latitude.to_f, longitude.to_f]
  end
  
  def has_location?
    latitude.present? && longitude.present?
  end
  
  def location_name
    location.presence || "Unknown location"
  end
  
  def total_participants_amount
    expense_participants.sum(:amount_owed)
  end
  
  def split_equally_among(users)
    return if users.empty?
    
    amount_per_person = (amount / users.count).round(2)
    remainder = amount - (amount_per_person * users.count)
    
    # Clear existing participants
    expense_participants.destroy_all
    
    # Create new participants
    users.each_with_index do |user, index|
      participant_amount = amount_per_person
      # Add remainder to first person to handle rounding
      participant_amount += remainder if index == 0
      
      expense_participants.create!(user: user, amount_owed: participant_amount)
    end
  end
  
  def category_emoji
    case category
    when 'food' then '🍽️'
    when 'accommodation' then '🏨'
    when 'transport' then '🚗'
    when 'activities' then '🎯'
    when 'shopping' then '🛒'
    else '💰'
    end
  end
  
  def formatted_amount(with_currency: true)
    formatted = "%.2f" % amount
    with_currency ? "#{formatted} #{currency}" : formatted
  end
  
  private
  
  def set_expense_date
    self.expense_date ||= Date.current
  end
end
