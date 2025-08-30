class Api::FoodItemsController < ApplicationController
  before_action :require_authentication
  
  def search
    query = params[:q].to_s.strip
    
    if query.present?
      food_items = FoodItem.where("LOWER(name) LIKE LOWER(?)", "%#{query}%")
                          .order(:name)
                          .limit(10)
                          .select(:id, :name, :standard_unit, :category)
    else
      food_items = FoodItem.none
    end
    
    render json: food_items.map { |item|
      {
        id: item.id,
        name: item.name,
        unit: item.standard_unit,
        category: item.category
      }
    }
  end
end