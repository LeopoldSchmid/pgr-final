class JournalEntry < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  
  has_one_attached :image
  
  validates :content, presence: true
  validates :entry_date, presence: true
  validates :latitude, presence: true, if: :longitude?
  validates :longitude, presence: true, if: :latitude?
  
  scope :favorites, -> { where(favorite: true) }
  scope :by_date, -> { order(:entry_date, :created_at) }
  scope :recent, -> { order(created_at: :desc) }
  scope :with_location, -> { where.not(latitude: nil, longitude: nil) }
  scope :with_images, -> { joins(:image_attachment) }
  
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
