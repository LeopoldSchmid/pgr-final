class TripMember < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  
  validates :role, inclusion: { in: %w[owner admin member guest] }
  validates :user_id, uniqueness: { scope: :trip_id, message: 'is already a member of this trip' }
  validates :joined_at, presence: true
  
  before_validation :set_joined_at, on: :create
  
  scope :owners, -> { where(role: 'owner') }
  scope :admins, -> { where(role: 'admin') }
  scope :members, -> { where(role: 'member') }
  scope :guests, -> { where(role: 'guest') }
  scope :active_members, -> { where(role: %w[owner admin member]) }
  
  def owner?
    role == 'owner'
  end
  
  def admin?
    role == 'admin'
  end
  
  def member?
    role == 'member'
  end
  
  def guest?
    role == 'guest'
  end
  
  def can_manage_expenses?
    %w[owner admin member].include?(role)
  end
  
  def can_edit_trip?
    %w[owner admin].include?(role)
  end
  
  private
  
  def set_joined_at
    self.joined_at ||= Time.current
  end
end
