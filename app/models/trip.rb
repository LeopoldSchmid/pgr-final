class Trip < ApplicationRecord
  belongs_to :user
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: %w[planning active completed] }
  
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
end
