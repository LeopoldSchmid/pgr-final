class ShoppingItem < ApplicationRecord
  belongs_to :shopping_list

  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :purchased_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :category, inclusion: { in: %w[produce dairy meat seafood pantry spices frozen other] }
  validates :source_type, inclusion: { in: %w[Recipe Manual] }
  validate :purchased_quantity_does_not_exceed_quantity
  validate :quantified_items_need_unit

  scope :purchased, -> {
    where("(quantity IS NOT NULL AND purchased_quantity >= quantity) OR (quantity IS NULL AND purchased = ?)", true)
  }
  scope :remaining, -> {
    where("(quantity IS NOT NULL AND purchased_quantity < quantity) OR (quantity IS NULL AND (purchased IS NULL OR purchased = ?))", false)
  }
  scope :partial, -> { where("quantity IS NOT NULL AND purchased_quantity > 0 AND purchased_quantity < quantity") }
  scope :by_category, ->(category) { where(category: category) }
  scope :from_recipes, -> { where(source_type: "Recipe") }
  scope :manual, -> { where(source_type: "Manual") }

  before_validation :set_defaults, on: :create
  before_validation :sync_purchase_state

  def formatted_quantity
    return "" unless quantity.present?

    if quantity == quantity.to_i
      "#{quantity.to_i} #{unit}"
    else
      "#{quantity} #{unit}"
    end
  end

  def formatted_purchased_quantity
    format_quantity(purchased_quantity)
  end

  def formatted_remaining_quantity
    return "" unless remaining_quantity.present?

    format_quantity(remaining_quantity)
  end

  def required_quantity
    quantity
  end

  def required_quantity=(value)
    self.quantity = value
  end

  def trackable_quantity?
    quantity.present?
  end

  def remaining_quantity
    return nil unless trackable_quantity?

    remaining = quantity.to_d - purchased_quantity.to_d
    remaining.positive? ? remaining : 0.to_d
  end

  def fully_purchased?
    if trackable_quantity?
      purchased_quantity.to_d >= quantity.to_d
    else
      purchased?
    end
  end

  def partially_purchased?
    trackable_quantity? && purchased_quantity.to_d.positive? && purchased_quantity.to_d < quantity.to_d
  end

  def purchase_status
    return "done" if fully_purchased?
    return "partial" if partially_purchased?

    "open"
  end

  def source_recipe
    return nil unless source_type == "Recipe" && source_id.present?
    Recipe.find_by(id: source_id)
  end

  def category_emoji
    case category
    when "produce" then "🥕"
    when "dairy" then "🥛"
    when "meat" then "🥩"
    when "seafood" then "🐟"
    when "pantry" then "🏪"
    when "spices" then "🧄"
    when "frozen" then "🧊"
    else "📦"
    end
  end

  def toggle_purchased!
    if trackable_quantity?
      fully_purchased? ? clear_purchase! : mark_complete!
    else
      update!(purchased: !purchased)
    end
  end

  def add_purchase!(amount)
    amount = BigDecimal(amount.to_s)
    raise ArgumentError, "Purchase amount must be positive" unless amount.positive?
    raise ArgumentError, "Cannot add a partial purchase without a required quantity" unless trackable_quantity?

    new_value = purchased_quantity.to_d + amount
    update!(purchased_quantity: [ new_value, quantity.to_d ].min)
  end

  def mark_complete!
    return update!(purchased: true) unless trackable_quantity?

    update!(purchased_quantity: quantity)
  end

  def clear_purchase!
    if trackable_quantity?
      update!(purchased_quantity: 0)
    else
      update!(purchased: false)
    end
  end

  private

  def format_quantity(value)
    return "" unless value.present?

    if value == value.to_i
      "#{value.to_i} #{unit}"
    else
      "#{value} #{unit}"
    end
  end

  def set_defaults
    self.category ||= "other"
    self.purchased ||= false
    self.purchased_quantity ||= 0
    self.source_type ||= "Manual"
  end

  def sync_purchase_state
    self.purchased = fully_purchased?
  end

  def purchased_quantity_does_not_exceed_quantity
    return unless trackable_quantity?
    return unless purchased_quantity.present? && quantity.present?
    return if purchased_quantity.to_d <= quantity.to_d

    errors.add(:purchased_quantity, "cannot exceed required quantity")
  end

  def quantified_items_need_unit
    return unless trackable_quantity?
    return if unit.present?

    errors.add(:unit, "can't be blank")
  end
end
