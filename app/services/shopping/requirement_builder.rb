module Shopping
  class RequirementBuilder
    Entry = Struct.new(:matching_key, :attributes, keyword_init: true)

    def initialize(trip)
      @trip = trip
    end

    def call
      meal_plans.map do |meal_plan|
        meal_plan.recipe.ingredients.map do |ingredient|
          build_entry(meal_plan, ingredient)
        end
      end.flatten
    end

    private

    attr_reader :trip

    def meal_plans
      trip.meal_plans.includes(recipe: :ingredients).ordered
    end

    def build_entry(meal_plan, ingredient)
      @current_meal_servings = meal_plan.servings.to_d

      food_item = ingredient.food_item
      unit = target_unit_for(ingredient, food_item)
      quantity = target_quantity_for(ingredient, food_item, unit)
      name = food_item&.name.presence || ingredient.name
      category = food_item&.category.presence || ingredient.category
      source_label = [ meal_plan.date&.iso8601, meal_plan.meal_type, meal_plan.recipe.name ].compact.join(" | ")

      attrs = {
        trip: trip,
        meal_plan: meal_plan,
        recipe: meal_plan.recipe,
        food_item: food_item,
        name: name,
        quantity: quantity,
        unit: unit,
        category: category,
        source_type: "meal_plan",
        sync_status: "in_sync",
        source_label: source_label,
        source_signature: signature_for(meal_plan, ingredient, quantity, unit, name, category),
        last_synced_signature: signature_for(meal_plan, ingredient, quantity, unit, name, category)
      }

      Entry.new(matching_key: matching_key_for(meal_plan, food_item, name, unit), attributes: attrs)
    ensure
      @current_meal_servings = nil
    end

    def target_unit_for(ingredient, food_item)
      food_item&.standard_unit.presence || ingredient.unit
    end

    def target_quantity_for(ingredient, food_item, unit)
      quantity = ingredient.quantity.to_d * serving_scale_for(ingredient.recipe)
      quantity = FoodItem.convert_quantity(quantity, ingredient.unit, unit) if food_item.present?
      quantity.to_d.round(2)
    end

    def serving_scale_for(recipe)
      recipe_servings = recipe&.servings.to_d
      recipe_servings = 1 if recipe_servings <= 0

      meal_servings = @current_meal_servings
      meal_servings = recipe_servings if meal_servings <= 0

      meal_servings / recipe_servings
    end

    def matching_key_for(meal_plan, food_item, name, unit)
      if food_item.present?
        [ meal_plan.id, "food_item", food_item.id, unit ].join(":")
      else
        [ meal_plan.id, "name", name.to_s.downcase, unit.to_s.downcase ].join(":")
      end
    end

    def signature_for(meal_plan, ingredient, quantity, unit, name, category)
      payload = {
        meal_plan_id: meal_plan.id,
        recipe_id: meal_plan.recipe_id,
        ingredient_id: ingredient.id,
        ingredient_updated_at: ingredient.updated_at,
        recipe_updated_at: meal_plan.recipe.updated_at,
        meal_plan_updated_at: meal_plan.updated_at,
        name: name,
        quantity: quantity.to_s,
        unit: unit,
        category: category
      }

      Digest::SHA256.hexdigest(payload.to_json)
    end
  end
end
