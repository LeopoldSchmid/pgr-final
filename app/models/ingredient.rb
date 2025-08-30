class Ingredient < ApplicationRecord
  belongs_to :recipe
  belongs_to :food_item, optional: true
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit, presence: true, length: { maximum: 20 }
  validates :category, inclusion: { in: %w[produce dairy meat seafood pantry spices frozen other] }
  
  before_validation :set_from_food_item, if: :food_item_changed?
  
  def formatted_quantity
    if quantity == quantity.to_i
      "#{quantity.to_i} #{unit}"
    else
      "#{quantity} #{unit}"
    end
  end
  
  def category_emoji
    case category
    when 'produce' then '🥕'
    when 'dairy' then '🥛'
    when 'meat' then '🥩'
    when 'seafood' then '🐟'
    when 'pantry' then '🏪'
    when 'spices' then '🧄'
    when 'frozen' then '🧊'
    else '📦'
    end
  end
  
  private
  
  def set_from_food_item
    if food_item
      self.name ||= food_item.name
      self.unit ||= food_item.standard_unit
      self.category ||= food_item.category
    end
  end
end
