class Recipe < ApplicationRecord
  belongs_to :trip, optional: true
  belongs_to :user # recipe creator/owner
  belongs_to :parent_recipe, class_name: 'Recipe', optional: true
  has_many :child_recipes, class_name: 'Recipe', foreign_key: 'parent_recipe_id', dependent: :nullify
  has_many :ingredients, dependent: :destroy
  
  validates :name, presence: true, length: { maximum: 100 }
  validates :servings, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :source_type, inclusion: { in: %w[public personal trip] }
  validates :trip, presence: true, if: -> { source_type == 'trip' }
  validates :trip, absence: true, if: -> { source_type == 'personal' }
  
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank
  
  scope :selected_for_shopping, -> { where(selected_for_shopping: true) }
  scope :public_recipes, -> { where(source_type: 'public') }
  scope :personal_recipes, ->(user) { where(source_type: 'personal', user: user) }
  scope :trip_recipes, -> { where(source_type: 'trip') }
  scope :proposed_for_public, -> { where(proposed_for_public: true) }
  
  before_validation :set_defaults, on: :create
  
  def scaled_ingredients_for(people_count)
    scale_factor = people_count.to_f / servings
    ingredients.map do |ingredient|
      scaled_quantity = (ingredient.quantity * scale_factor).round(1)
      {
        name: ingredient.name,
        quantity: scaled_quantity,
        unit: ingredient.unit,
        category: ingredient.category
      }
    end
  end
  
  def copy_to_personal(new_user, new_name = nil)
    Recipe.create!(
      name: new_name || "#{name} (Copy)",
      description: description,
      servings: servings,
      source_type: 'personal',
      user: new_user,
      parent_recipe: self,
      trip: nil, # Personal recipes don't belong to trips
      ingredients_attributes: ingredients.map { |ing|
        {
          name: ing.name,
          quantity: ing.quantity,
          unit: ing.unit,
          category: ing.category,
          food_item_id: ing.food_item_id
        }
      }
    )
  end
  
  def copy_to_trip(trip, scaled_servings = nil)
    new_servings = scaled_servings || servings
    scale_factor = new_servings.to_f / servings
    
    Recipe.create!(
      name: name,
      description: description,
      servings: new_servings,
      source_type: 'trip',
      user: user,
      parent_recipe: self,
      trip: trip,
      ingredients_attributes: ingredients.map { |ing|
        {
          name: ing.name,
          quantity: (ing.quantity * scale_factor).round(1),
          unit: ing.unit,
          category: ing.category,
          food_item_id: ing.food_item_id
        }
      }
    )
  end
  
  def propose_for_public!
    update!(proposed_for_public: true)
  end
  
  def is_public?
    source_type == 'public'
  end
  
  def is_personal?
    source_type == 'personal'  
  end
  
  def is_trip_recipe?
    source_type == 'trip'
  end
  
  private
  
  def set_defaults
    self.selected_for_shopping ||= false
    self.source_type ||= 'trip'
    self.proposed_for_public ||= false
  end
end
