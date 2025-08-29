class JournalEntry < ApplicationRecord
  belongs_to :trip
  belongs_to :user
  
  validates :content, presence: true
  validates :entry_date, presence: true
  
  scope :favorites, -> { where(favorite: true) }
  scope :by_date, -> { order(:entry_date, :created_at) }
  scope :recent, -> { order(created_at: :desc) }
  
  def favorite?
    favorite == true
  end
  
  def toggle_favorite!
    update!(favorite: !favorite?)
  end
end
