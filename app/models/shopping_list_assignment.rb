class ShoppingListAssignment < ApplicationRecord
  belongs_to :shopping_requirement
  belongs_to :shopping_list

  has_many :shopping_item_comments, dependent: :destroy

  validates :planned_quantity, presence: true, numericality: { greater_than: 0 }
  validates :purchased_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :unit, presence: true, length: { maximum: 20 }
  validate :purchased_quantity_does_not_exceed_planned_quantity
  validate :unit_matches_requirement_dimension

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :open_only, -> { where("purchased_quantity < planned_quantity") }
  scope :done, -> { where("purchased_quantity >= planned_quantity") }

  def remaining_quantity
    remaining = planned_quantity.to_d - purchased_quantity.to_d
    remaining.positive? ? remaining : 0.to_d
  end

  def purchase_status
    return "done" if purchased_quantity.to_d >= planned_quantity.to_d
    return "partial" if purchased_quantity.to_d.positive?

    "open"
  end

  def add_purchase!(amount)
    amount = BigDecimal(amount.to_s)
    raise ArgumentError, "Purchase amount must be positive" unless amount.positive?

    update!(purchased_quantity: [ purchased_quantity.to_d + amount, planned_quantity.to_d ].min)
  end

  def mark_complete!
    update!(purchased_quantity: planned_quantity)
  end

  def clear_purchase!
    update!(purchased_quantity: 0)
  end

  private

  def purchased_quantity_does_not_exceed_planned_quantity
    return unless purchased_quantity.present? && planned_quantity.present?
    return if purchased_quantity.to_d <= planned_quantity.to_d

    errors.add(:purchased_quantity, "cannot exceed planned quantity")
  end

  def unit_matches_requirement_dimension
    return unless shopping_requirement&.unit.present? && unit.present?
    return if FoodItem.compatible_units?(shopping_requirement.unit, unit) || shopping_requirement.unit == unit

    errors.add(:unit, "must be compatible with the requirement unit")
  end
end
