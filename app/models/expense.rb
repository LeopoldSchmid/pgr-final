class Expense < ApplicationRecord
  belongs_to :trip
  belongs_to :payer, class_name: "User", optional: true
  belongs_to :payer_trip_person, class_name: "TripPerson", optional: true
  has_many :expense_participants, dependent: :destroy
  has_many :participants, through: :expense_participants, source: :user
  has_many :expense_splits, dependent: :destroy
  has_many :split_trip_people, through: :expense_splits, source: :trip_person
  has_one_attached :receipt

  STATUSES = %w[draft active needs_split voided].freeze
  
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :description, presence: true, length: { maximum: 200 }
  validates :category, inclusion: { in: %w[food accommodation transport activities shopping other] }
  validates :currency, presence: true, length: { is: 3 }
  validates :expense_date, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :payer_trip_person, presence: true
  validates :latitude, presence: true, if: :longitude?
  validates :longitude, presence: true, if: :latitude?
  validate :payer_trip_person_belongs_to_trip
  validate :active_expense_splits_sum_to_amount, if: :validate_active_split_total?
  
  scope :by_date, -> { order(:expense_date, :created_at) }
  scope :recent, -> { order(created_at: :desc) }
  scope :by_category, ->(category) { where(category: category) }
  scope :by_payer, ->(user) { where(payer: user) }
  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }
  
  before_validation :set_expense_date, on: :create
  before_validation :set_payer_trip_person_from_payer
  
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
    expense_splits.loaded? || expense_splits.exists? ? expense_splits.sum(:amount_owed) : expense_participants.sum(:amount_owed)
  end

  def split_equally_among(users)
    return if users.empty?

    amount_per_person = (amount / users.count).round(2)
    remainder = amount - (amount_per_person * users.count)

    # Clear existing participants
    expense_participants.destroy_all
    expense_splits.destroy_all

    # Create new participants
    users.each_with_index do |user, index|
      participant_amount = amount_per_person
      # Add remainder to first person to handle rounding
      participant_amount += remainder if index == 0

      expense_participants.create!(user: user, amount_owed: participant_amount)
    end

    trip_people = users.map { |user| trip.trip_person_for(user) }
    apply_split!(Expenses::SplitCalculator.equal(amount: amount, trip_people: trip_people))
  end

  def apply_split!(results)
    split_results = Array(results)
    split_total = split_results.sum { |result| result.amount_owed.to_d }
    unless split_total == amount
      raise ActiveRecord::RecordInvalid.new(self.tap { |expense| expense.errors.add(:expense_splits, "must sum to the expense amount") })
    end

    transaction do
      expense_splits.destroy_all

      split_results.each do |result|
        expense_splits.create!(
          trip_person: result.trip_person,
          amount_owed: result.amount_owed,
          split_method: result.split_method,
          split_value: result.split_value,
          split_metadata: result.split_metadata
        )
      end

      update!(status: "active")
    end
  end

  def active_for_settlement?
    status == "active"
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

  def set_payer_trip_person_from_payer
    return if payer_trip_person.present? || payer.blank? || trip.blank?

    self.payer_trip_person = trip.trip_person_for(payer)
  end

  def payer_trip_person_belongs_to_trip
    return if payer_trip_person.blank? || trip.blank?

    if payer_trip_person.trip_id != trip_id
      errors.add(:payer_trip_person, "must belong to the expense trip")
    end
  end

  def validate_active_split_total?
    status == "active" && expense_splits.loaded? && expense_splits.any?
  end

  def active_expense_splits_sum_to_amount
    split_total = expense_splits.sum(&:amount_owed)
    return if split_total == amount

    errors.add(:expense_splits, "must sum to the expense amount")
  end
end
