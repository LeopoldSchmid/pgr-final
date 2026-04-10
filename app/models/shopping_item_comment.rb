class ShoppingItemComment < ApplicationRecord
  belongs_to :shopping_list_assignment
  belongs_to :user

  validates :body, presence: true

  scope :ordered, -> { order(created_at: :asc) }

  def resolved?
    resolved_at.present?
  end
end
