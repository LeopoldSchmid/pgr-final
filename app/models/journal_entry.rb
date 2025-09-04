class JournalEntry < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  
  has_many_attached :images
  has_many :comments, dependent: :destroy
  
  validates :content, presence: true
  validates :entry_date, presence: true
  validates :latitude, presence: true, if: :longitude?
  validates :longitude, presence: true, if: :latitude?
  validates :category, inclusion: { in: %w(restaurant hotel attraction transport shopping other), allow_nil: true }
  
  scope :favorites, -> { where(favorite: true) }
  scope :by_date, -> { order(:entry_date, :created_at) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }
  scope :with_images, -> { joins(:images_attachments).distinct }
  scope :global_favorites, -> { where(global_favorite: true) }
  
  def favorite?
    favorite == true
  end
  
  def toggle_favorite!
    update!(favorite: !favorite?)
  end
  
  def has_location?
    latitude.present? && longitude.present?
  end
  
  def coordinates
    return nil unless has_location?
    [latitude.to_f, longitude.to_f]
  end
  
  def location_name
    return location if location.present?
    return "📍 #{latitude.round(4)}, #{longitude.round(4)}" if has_location?
    nil
  end
end
