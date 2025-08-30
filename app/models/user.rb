class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :trips, dependent: :destroy # trips user created
  has_many :trip_members, dependent: :destroy
  has_many :member_trips, through: :trip_members, source: :trip # trips user is member of
  has_many :paid_expenses, class_name: 'Expense', foreign_key: 'payer_id', dependent: :destroy
  has_many :expense_participants, dependent: :destroy
  has_many :participated_expenses, through: :expense_participants, source: :expense

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  
  def all_trips
    Trip.where(id: (trips.pluck(:id) + member_trips.pluck(:id)).uniq)
  end
end
