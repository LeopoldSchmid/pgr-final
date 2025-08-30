# Common food items with standardized units and categories (metric only)

food_items = [
  # Produce - weight based
  { name: "Tomatoes", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Onions", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Carrots", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Potatoes", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Bell peppers", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Garlic", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Ginger", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Lettuce", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Spinach", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Mushrooms", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Broccoli", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Cauliflower", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Zucchini", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Eggplant", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Cucumber", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Avocado", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Lemons", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Limes", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Oranges", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Apples", standard_unit: "g", category: "produce", unit_type: "weight" },

  # Produce - count based
  { name: "Eggs", standard_unit: "pieces", category: "produce", unit_type: "count" },

  # Dairy - volume based
  { name: "Milk", standard_unit: "ml", category: "dairy", unit_type: "volume" },
  { name: "Heavy cream", standard_unit: "ml", category: "dairy", unit_type: "volume" },
  { name: "Greek yogurt", standard_unit: "ml", category: "dairy", unit_type: "volume" },
  
  # Dairy - weight based
  { name: "Butter", standard_unit: "g", category: "dairy", unit_type: "weight" },
  { name: "Parmesan cheese", standard_unit: "g", category: "dairy", unit_type: "weight" },
  { name: "Mozzarella cheese", standard_unit: "g", category: "dairy", unit_type: "weight" },
  { name: "Cheddar cheese", standard_unit: "g", category: "dairy", unit_type: "weight" },
  { name: "Feta cheese", standard_unit: "g", category: "dairy", unit_type: "weight" },
  { name: "Cream cheese", standard_unit: "g", category: "dairy", unit_type: "weight" },

  # Meat - weight based
  { name: "Chicken breast", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Chicken thighs", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Ground beef", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Beef steak", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Pork tenderloin", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Bacon", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Ham", standard_unit: "g", category: "meat", unit_type: "weight" },
  { name: "Sausages", standard_unit: "g", category: "meat", unit_type: "weight" },

  # Seafood - weight based
  { name: "Salmon", standard_unit: "g", category: "seafood", unit_type: "weight" },
  { name: "Tuna", standard_unit: "g", category: "seafood", unit_type: "weight" },
  { name: "Cod", standard_unit: "g", category: "seafood", unit_type: "weight" },
  { name: "Shrimp", standard_unit: "g", category: "seafood", unit_type: "weight" },
  { name: "Mussels", standard_unit: "g", category: "seafood", unit_type: "weight" },

  # Pantry - weight based
  { name: "Spaghetti", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Penne pasta", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Rice", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Quinoa", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Flour", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Sugar", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Brown sugar", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Rolled oats", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Breadcrumbs", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Almonds", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Walnuts", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Pine nuts", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Chickpeas", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Black beans", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Lentils", standard_unit: "g", category: "pantry", unit_type: "weight" },

  # Pantry - volume based
  { name: "Olive oil", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Vegetable oil", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Coconut oil", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Vinegar", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Balsamic vinegar", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Soy sauce", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Honey", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Vanilla extract", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Vegetable broth", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Chicken broth", standard_unit: "ml", category: "pantry", unit_type: "volume" },

  # Canned goods - weight based (drained weight)
  { name: "Canned tomatoes", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Tomato paste", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Canned corn", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Canned beans", standard_unit: "g", category: "pantry", unit_type: "weight" },

  # Spices - weight based (small amounts)
  { name: "Salt", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Black pepper", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Paprika", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Cumin", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Coriander", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Turmeric", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Cinnamon", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Oregano", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Basil", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Thyme", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Rosemary", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Bay leaves", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Chili powder", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Garlic powder", standard_unit: "g", category: "spices", unit_type: "weight" },
  { name: "Onion powder", standard_unit: "g", category: "spices", unit_type: "weight" },

  # Fresh herbs - weight based
  { name: "Fresh parsley", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Fresh cilantro", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Fresh basil", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Fresh mint", standard_unit: "g", category: "produce", unit_type: "weight" },
  { name: "Fresh dill", standard_unit: "g", category: "produce", unit_type: "weight" },

  # Frozen items - weight based
  { name: "Frozen peas", standard_unit: "g", category: "frozen", unit_type: "weight" },
  { name: "Frozen corn", standard_unit: "g", category: "frozen", unit_type: "weight" },
  { name: "Frozen berries", standard_unit: "g", category: "frozen", unit_type: "weight" },
  { name: "Frozen spinach", standard_unit: "g", category: "frozen", unit_type: "weight" },

  # Bread and bakery - weight based
  { name: "Bread", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Baguette", standard_unit: "g", category: "pantry", unit_type: "weight" },
  { name: "Tortillas", standard_unit: "g", category: "pantry", unit_type: "weight" },

  # Condiments - volume based
  { name: "Mustard", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Ketchup", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Mayonnaise", standard_unit: "ml", category: "pantry", unit_type: "volume" },
  { name: "Hot sauce", standard_unit: "ml", category: "pantry", unit_type: "volume" }
]

puts "Creating #{food_items.count} food items..."

food_items.each do |item_attrs|
  food_item = FoodItem.find_or_create_by(name: item_attrs[:name]) do |item|
    item.standard_unit = item_attrs[:standard_unit]
    item.category = item_attrs[:category]
    item.unit_type = item_attrs[:unit_type]
  end
  
  if food_item.persisted?
    puts "✓ #{food_item.name} (#{food_item.standard_unit})"
  else
    puts "✗ Failed to create #{item_attrs[:name]}: #{food_item.errors.full_messages.join(', ')}"
  end
end

puts "Finished creating food items database!"