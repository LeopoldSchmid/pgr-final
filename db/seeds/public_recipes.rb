# Create public recipes that everyone can use

# For public recipes, we need a system user. Let's create one if it doesn't exist.
system_user = User.find_or_create_by!(email_address: "system@plangoreminisce.com") do |user|
  user.password = SecureRandom.hex(32) # Random password since no one should log in as system
  user.password_confirmation = user.password
end

puts "Created/found system user for public recipes"

# Define public recipes with ingredients from our FoodItem database
public_recipes_data = [
  {
    name: "Classic Spaghetti Carbonara",
    description: "Traditional Italian pasta with eggs, cheese, and pancetta",
    servings: 4,
    ingredients: [
      { name: "Spaghetti", quantity: 400, unit: "g", category: "pantry" },
      { name: "Eggs", quantity: 4, unit: "pieces", category: "produce" },
      { name: "Parmesan cheese", quantity: 100, unit: "g", category: "dairy" },
      { name: "Bacon", quantity: 150, unit: "g", category: "meat" },
      { name: "Black pepper", quantity: 2, unit: "g", category: "spices" },
      { name: "Salt", quantity: 3, unit: "g", category: "spices" }
    ]
  },
  {
    name: "Simple Tomato Pasta",
    description: "Quick and easy pasta with fresh tomato sauce",
    servings: 2,
    ingredients: [
      { name: "Penne pasta", quantity: 200, unit: "g", category: "pantry" },
      { name: "Canned tomatoes", quantity: 400, unit: "g", category: "pantry" },
      { name: "Onions", quantity: 100, unit: "g", category: "produce" },
      { name: "Garlic", quantity: 10, unit: "g", category: "produce" },
      { name: "Olive oil", quantity: 30, unit: "ml", category: "pantry" },
      { name: "Fresh basil", quantity: 10, unit: "g", category: "produce" },
      { name: "Salt", quantity: 2, unit: "g", category: "spices" }
    ]
  },
  {
    name: "Chicken Stir Fry",
    description: "Healthy stir fry with mixed vegetables",
    servings: 3,
    ingredients: [
      { name: "Chicken breast", quantity: 300, unit: "g", category: "meat" },
      { name: "Bell peppers", quantity: 200, unit: "g", category: "produce" },
      { name: "Broccoli", quantity: 150, unit: "g", category: "produce" },
      { name: "Carrots", quantity: 100, unit: "g", category: "produce" },
      { name: "Soy sauce", quantity: 50, unit: "ml", category: "pantry" },
      { name: "Vegetable oil", quantity: 20, unit: "ml", category: "pantry" },
      { name: "Ginger", quantity: 10, unit: "g", category: "produce" },
      { name: "Garlic", quantity: 10, unit: "g", category: "produce" }
    ]
  },
  {
    name: "Greek Salad",
    description: "Fresh Mediterranean salad with feta cheese",
    servings: 4,
    ingredients: [
      { name: "Tomatoes", quantity: 300, unit: "g", category: "produce" },
      { name: "Cucumber", quantity: 200, unit: "g", category: "produce" },
      { name: "Feta cheese", quantity: 100, unit: "g", category: "dairy" },
      { name: "Onions", quantity: 50, unit: "g", category: "produce" },
      { name: "Olive oil", quantity: 60, unit: "ml", category: "pantry" },
      { name: "Oregano", quantity: 2, unit: "g", category: "spices" },
      { name: "Salt", quantity: 2, unit: "g", category: "spices" }
    ]
  },
  {
    name: "Beef Tacos",
    description: "Tasty ground beef tacos with fresh toppings",
    servings: 4,
    ingredients: [
      { name: "Ground beef", quantity: 400, unit: "g", category: "meat" },
      { name: "Tortillas", quantity: 200, unit: "g", category: "pantry" },
      { name: "Lettuce", quantity: 100, unit: "g", category: "produce" },
      { name: "Tomatoes", quantity: 150, unit: "g", category: "produce" },
      { name: "Cheddar cheese", quantity: 100, unit: "g", category: "dairy" },
      { name: "Onions", quantity: 80, unit: "g", category: "produce" },
      { name: "Cumin", quantity: 3, unit: "g", category: "spices" },
      { name: "Chili powder", quantity: 5, unit: "g", category: "spices" }
    ]
  },
  {
    name: "Salmon with Rice",
    description: "Healthy baked salmon with steamed rice",
    servings: 2,
    ingredients: [
      { name: "Salmon", quantity: 300, unit: "g", category: "seafood" },
      { name: "Rice", quantity: 150, unit: "g", category: "pantry" },
      { name: "Broccoli", quantity: 200, unit: "g", category: "produce" },
      { name: "Lemons", quantity: 60, unit: "g", category: "produce" },
      { name: "Olive oil", quantity: 20, unit: "ml", category: "pantry" },
      { name: "Salt", quantity: 2, unit: "g", category: "spices" },
      { name: "Black pepper", quantity: 1, unit: "g", category: "spices" }
    ]
  }
]

puts "Creating #{public_recipes_data.count} public recipes..."

public_recipes_data.each do |recipe_data|
  puts "Creating: #{recipe_data[:name]}"
  
  recipe = Recipe.create!(
    name: recipe_data[:name],
    description: recipe_data[:description],
    servings: recipe_data[:servings],
    source_type: 'public',
    user: system_user,
    trip: nil # Public recipes don't belong to trips
  )
  
  # Add ingredients with food item references
  recipe_data[:ingredients].each do |ingredient_data|
    food_item = FoodItem.find_by(name: ingredient_data[:name])
    
    recipe.ingredients.create!(
      name: ingredient_data[:name],
      quantity: ingredient_data[:quantity],
      unit: ingredient_data[:unit],
      category: ingredient_data[:category],
      food_item: food_item
    )
  end
  
  puts "✓ #{recipe.name} created with #{recipe.ingredients.count} ingredients"
end

puts "Finished creating public recipes database!"