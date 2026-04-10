# Standard food items for recipes, meal-planning requirements, and manual shopping input.
# Pragmatic default rule:
# - mostly kg or l
# - obvious count-based exceptions use pieces
# - existing items are updated so seeds remain the source of truth

food_items = [
  # Produce
  { name: "Tomatoes", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Potatoes", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Carrots", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Bell peppers", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Zucchini", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Eggplant", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Broccoli", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Cauliflower", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Mushrooms", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Spinach", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Fresh parsley", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Fresh cilantro", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Fresh basil", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Fresh mint", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Fresh dill", standard_unit: "kg", category: "produce", unit_type: "weight" },
  { name: "Ginger", standard_unit: "kg", category: "produce", unit_type: "weight" },

  # Produce - obvious count-based exceptions
  { name: "Cucumber", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Avocado", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Lettuce", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Onions", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Garlic", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Lemons", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Limes", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Oranges", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Apples", standard_unit: "pieces", category: "produce", unit_type: "count" },
  { name: "Eggs", standard_unit: "pieces", category: "produce", unit_type: "count" },

  # Dairy
  { name: "Milk", standard_unit: "l", category: "dairy", unit_type: "volume" },
  { name: "Heavy cream", standard_unit: "l", category: "dairy", unit_type: "volume" },
  { name: "Greek yogurt", standard_unit: "l", category: "dairy", unit_type: "volume" },
  { name: "Butter", standard_unit: "kg", category: "dairy", unit_type: "weight" },
  { name: "Parmesan cheese", standard_unit: "kg", category: "dairy", unit_type: "weight" },
  { name: "Cheddar cheese", standard_unit: "kg", category: "dairy", unit_type: "weight" },
  { name: "Feta cheese", standard_unit: "kg", category: "dairy", unit_type: "weight" },
  { name: "Cream cheese", standard_unit: "kg", category: "dairy", unit_type: "weight" },
  { name: "Mozzarella", standard_unit: "pieces", category: "dairy", unit_type: "count" },
  { name: "Mozzarella cheese", standard_unit: "pieces", category: "dairy", unit_type: "count" },

  # Meat
  { name: "Chicken breast", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Chicken thighs", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Ground beef", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Beef steak", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Pork tenderloin", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Bacon", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Ham", standard_unit: "kg", category: "meat", unit_type: "weight" },
  { name: "Sausages", standard_unit: "kg", category: "meat", unit_type: "weight" },

  # Seafood
  { name: "Salmon", standard_unit: "kg", category: "seafood", unit_type: "weight" },
  { name: "Tuna", standard_unit: "kg", category: "seafood", unit_type: "weight" },
  { name: "Cod", standard_unit: "kg", category: "seafood", unit_type: "weight" },
  { name: "Shrimp", standard_unit: "kg", category: "seafood", unit_type: "weight" },
  { name: "Mussels", standard_unit: "kg", category: "seafood", unit_type: "weight" },

  # Pantry - dry goods
  { name: "Spaghetti", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Penne pasta", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Lasagne sheets", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Rice", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Quinoa", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Flour", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Sugar", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Brown sugar", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Rolled oats", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Breadcrumbs", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Almonds", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Walnuts", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Pine nuts", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Chickpeas", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Black beans", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Lentils", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Bread", standard_unit: "pieces", category: "pantry", unit_type: "count" },
  { name: "Baguette", standard_unit: "pieces", category: "pantry", unit_type: "count" },
  { name: "Tortillas", standard_unit: "pieces", category: "pantry", unit_type: "count" },

  # Pantry - liquids and sauces
  { name: "Olive oil", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Vegetable oil", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Coconut oil", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Vinegar", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Balsamic vinegar", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Soy sauce", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Honey", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Vanilla extract", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Vegetable broth", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Chicken broth", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Mustard", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Ketchup", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Mayonnaise", standard_unit: "l", category: "pantry", unit_type: "volume" },
  { name: "Hot sauce", standard_unit: "l", category: "pantry", unit_type: "volume" },

  # Canned / preserved
  { name: "Canned tomatoes", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Tomato paste", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Canned corn", standard_unit: "kg", category: "pantry", unit_type: "weight" },
  { name: "Canned beans", standard_unit: "kg", category: "pantry", unit_type: "weight" },

  # Spices
  { name: "Salt", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Black pepper", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Paprika", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Cumin", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Coriander", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Turmeric", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Cinnamon", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Oregano", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Basil", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Thyme", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Rosemary", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Bay leaves", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Chili powder", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Garlic powder", standard_unit: "kg", category: "spices", unit_type: "weight" },
  { name: "Onion powder", standard_unit: "kg", category: "spices", unit_type: "weight" },

  # Frozen
  { name: "Frozen peas", standard_unit: "kg", category: "frozen", unit_type: "weight" },
  { name: "Frozen corn", standard_unit: "kg", category: "frozen", unit_type: "weight" },
  { name: "Frozen berries", standard_unit: "kg", category: "frozen", unit_type: "weight" },
  { name: "Frozen spinach", standard_unit: "kg", category: "frozen", unit_type: "weight" },

  # Drinks / shared supplies
  { name: "Water", standard_unit: "l", category: "other", unit_type: "volume" },
  { name: "Sparkling water", standard_unit: "l", category: "other", unit_type: "volume" },
  { name: "Beer", standard_unit: "l", category: "other", unit_type: "volume" },
  { name: "Wine", standard_unit: "l", category: "other", unit_type: "volume" },
  { name: "Juice", standard_unit: "l", category: "other", unit_type: "volume" },
  { name: "Soft drinks", standard_unit: "l", category: "other", unit_type: "volume" },
  { name: "Coffee", standard_unit: "kg", category: "other", unit_type: "weight" },
  { name: "Tea", standard_unit: "kg", category: "other", unit_type: "weight" }
]

puts "Upserting #{food_items.count} food items..."

food_items.each do |attributes|
  food_item = FoodItem.find_or_initialize_by(name: attributes[:name])
  food_item.assign_attributes(
    standard_unit: attributes[:standard_unit],
    category: attributes[:category],
    unit_type: attributes[:unit_type]
  )
  food_item.save!
end

puts "Finished seeding food items."
