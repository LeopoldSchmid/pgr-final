class Invitation < ApplicationRecord
  belongs_to :trip
  belongs_to :invited_by, class_name: 'User'
  
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: %w[pending accepted declined expired] }
  validates :role, inclusion: { in: %w[guest member admin] }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true
  
  validate :email_not_already_member
  validate :not_expired, on: :accept
  
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :declined, -> { where(status: 'declined') }
  scope :active, -> { where(status: 'pending').where('expires_at > ?', Time.current) }
  
  before_validation :generate_token, on: :create
  before_validation :set_expiry, on: :create
  
  def expired?
    expires_at < Time.current
  end
  
  def can_be_accepted?
    pending? && !expired?
  end
  
  def accept!(user = nil)
    return false unless can_be_accepted?
    
    ActiveRecord::Base.transaction do
      # Mark as accepted first
      self.status = 'accepted'
      
      # If user is provided, add them to the trip
      if user
        trip.add_member(user, role: role) unless trip.has_member?(user)
      end
      
      # Save without running validations since we're accepting
      # The email_not_already_member validation doesn't make sense when accepting
      update_column(:status, 'accepted')
    end
    
    true
  end
  
  def decline!
    update!(status: 'declined') if pending?
  end
  
  def pending?
    status == 'pending'
  end
  
  private
  
  def generate_token
    self.token = SecureRandom.urlsafe_base64(32) if token.blank?
  end
  
  def set_expiry
    self.expires_at = 7.days.from_now if expires_at.blank?
  end
  
  def email_not_already_member
    return unless trip && email
    
    # Check if email already belongs to a trip member
    existing_user = User.find_by(email_address: email)
    if existing_user && trip.has_member?(existing_user)
      errors.add(:email, 'is already a member of this trip')
    end
    
    # Check for existing pending invitation
    if trip.invitations.pending.where.not(id: id).exists?(email: email)
      errors.add(:email, 'has already been invited to this trip')
    end
  end
  
  def not_expired
    errors.add(:base, 'This invitation has expired') if expired?
  end
end
