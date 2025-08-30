class ShoppingList < ApplicationRecord
  belongs_to :trip
  has_many :shopping_items, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :status, inclusion: { in: %w[draft active completed] }
  
  before_validation :set_defaults, on: :create
  
  def self.current_for_trip(trip)
    trip.shopping_lists.where(status: %w[draft active]).first ||
    trip.shopping_lists.create!(name: "Trip Shopping List")
  end
  
  def generate_from_recipes(selected_recipes, people_count = nil)
    # Clear existing recipe-generated items
    shopping_items.where(source_type: 'Recipe').destroy_all
    
    # Group ingredients by food item (with unit conversion) or by name if no food item
    ingredient_groups = {}
    
    selected_recipes.each do |recipe|
      recipe.ingredients.each do |ingredient|
        # Scale quantity if people_count is provided
        quantity = if people_count
          scale_factor = people_count.to_f / recipe.servings
          (ingredient.quantity * scale_factor).round(1)
        else
          ingredient.quantity
        end
        
        food_item = ingredient.food_item
        
        if food_item
          # Use food item for standardization - convert to standard unit
          standard_quantity = convert_to_standard_unit(
            quantity, 
            ingredient.unit, 
            food_item
          )
          
          key = "food_item_#{food_item.id}"
          standard_unit = food_item.standard_unit
          display_name = food_item.name
          category = food_item.category
        else
          # Fall back to name-based grouping for ingredients without food items
          key = "manual_#{ingredient.name}_#{ingredient.unit}"
          standard_quantity = quantity
          standard_unit = ingredient.unit
          display_name = ingredient.name
          category = ingredient.category
        end
        
        if ingredient_groups[key]
          ingredient_groups[key][:quantity] += standard_quantity
        else
          ingredient_groups[key] = {
            name: display_name,
            quantity: standard_quantity,
            unit: standard_unit,
            category: category,
            source_recipe: recipe,
            food_item_id: food_item&.id
          }
        end
      end
    end
    
    # Create shopping items from grouped ingredients
    ingredient_groups.values.each do |ingredient_data|
      shopping_items.create!(
        name: ingredient_data[:name],
        quantity: ingredient_data[:quantity].round(1), # Round to 1 decimal place
        unit: ingredient_data[:unit],
        category: ingredient_data[:category],
        source_type: 'Recipe',
        source_id: ingredient_data[:source_recipe].id,
        purchased: false
      )
    end
  end
  
  def add_manual_item(name, quantity = nil, unit = nil, category = 'other')
    shopping_items.create!(
      name: name,
      quantity: quantity,
      unit: unit,
      category: category,
      source_type: 'Manual',
      purchased: false
    )
  end
  
  def items_by_category
    shopping_items.includes(:shopping_list).group_by(&:category)
  end
  
  def completion_percentage
    return 0 if shopping_items.count == 0
    purchased_count = shopping_items.where(purchased: true).count
    (purchased_count.to_f / shopping_items.count * 100).round
  end
  
  private
  
  def convert_to_standard_unit(quantity, unit, food_item)
    # Use the FoodItem's conversion logic
    converted_quantity = FoodItem.convert_quantity(quantity, unit, food_item.standard_unit)
    converted_quantity || quantity # Fall back to original quantity if conversion fails
  end
  
  def set_defaults
    self.status ||= 'draft'
    self.name ||= "Shopping List"
  end
end
