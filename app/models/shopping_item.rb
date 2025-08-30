class ShoppingItem < ApplicationRecord
  belongs_to :shopping_list
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :quantity, numericality: { greater_than: 0 }, allow_nil: true
  validates :category, inclusion: { in: %w[produce dairy meat seafood pantry spices frozen other] }
  validates :source_type, inclusion: { in: %w[Recipe Manual] }
  
  scope :purchased, -> { where(purchased: true) }
  scope :remaining, -> { where(purchased: false) }
  scope :by_category, ->(category) { where(category: category) }
  scope :from_recipes, -> { where(source_type: 'Recipe') }
  scope :manual, -> { where(source_type: 'Manual') }
  
  before_validation :set_defaults, on: :create
  
  def formatted_quantity
    return '' unless quantity.present?
    
    if quantity == quantity.to_i
      "#{quantity.to_i} #{unit}"
    else
      "#{quantity} #{unit}"
    end
  end
  
  def source_recipe
    return nil unless source_type == 'Recipe' && source_id.present?
    Recipe.find_by(id: source_id)
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
  
  def toggle_purchased!
    update!(purchased: !purchased)
  end
  
  private
  
  def set_defaults
    self.category ||= 'other'
    self.purchased ||= false
    self.source_type ||= 'Manual'
  end
end
