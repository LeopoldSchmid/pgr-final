# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Create a test user for development
test_user = User.find_or_create_by!(email_address: "test@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

# Create sample trips to demonstrate the phase navigation
unless test_user.trips.exists?
  # Planning trip
  planning_trip = test_user.trips.create!(
    name: "Summer Cabin Retreat 2025",
    description: "Weekend getaway to the mountains with college friends. Planning to cook together, hike, and relax by the lake.",
    status: "planning",
    start_date: 3.months.from_now.to_date,
    end_date: 3.months.from_now.to_date + 3.days
  )

  # Active trip for THIS WEEKEND
  weekend_trip = test_user.trips.create!(
    name: "Weekend Adventure",
    description: "Ready to explore and create memories! Perfect for testing the journal feature.",
    status: "active",
    start_date: Date.current.next_occurring(:saturday),
    end_date: Date.current.next_occurring(:sunday)
  )

  # Active trip (current)
  current_trip = test_user.trips.create!(
    name: "City Food Tour",
    description: "Exploring local restaurants and food markets downtown.",
    status: "active",
    start_date: 1.day.ago.to_date,
    end_date: 2.days.from_now.to_date
  )

  # Completed trip with sample journal entries
  completed_trip = test_user.trips.create!(
    name: "Beach House Week",
    description: "Amazing week at the coast with family. Cooked fresh seafood every night!",
    status: "completed",
    start_date: 2.months.ago.to_date,
    end_date: 2.months.ago.to_date + 6.days
  )

  # Add sample journal entries to the completed trip with coordinates
  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Arrived at the beach house! The view is absolutely stunning. You can see the ocean from every window. The kids are already asking to go to the beach.",
    location: "Oceanview Beach House",
    entry_date: completed_trip.start_date,
    favorite: true,
    latitude: 40.7282,
    longitude: -73.7949
  )

  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Spent the morning collecting shells with the family. Found some amazing sand dollars. The afternoon was perfect for reading on the deck.",
    location: "Sandy Shore Beach",
    entry_date: completed_trip.start_date + 1.day,
    favorite: false,
    latitude: 40.7355,
    longitude: -73.8023
  )

  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Cooked the most amazing seafood pasta tonight! Fresh mussels and clams from the local market. Everyone said it was restaurant quality. Definitely saving this recipe.",
    location: "Beach House Kitchen",
    entry_date: completed_trip.start_date + 2.days,
    favorite: true,
    latitude: 40.7282,
    longitude: -73.7949
  )

  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Last day at the beach. Watched the sunrise from the deck with coffee. These moments of peace are what I'll remember most. Already planning to come back next year.",
    location: "Beach House Deck",
    entry_date: completed_trip.end_date,
    favorite: true,
    latitude: 40.7290,
    longitude: -73.7955
  )

  puts "Created sample trips and journal entries for testing"
end

# Create additional dummy users for testing expense splitting
alice = User.find_or_create_by!(email_address: "alice@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

bob = User.find_or_create_by!(email_address: "bob@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

charlie = User.find_or_create_by!(email_address: "charlie@example.com") do |user|
  user.password = "password123"
  user.password_confirmation = "password123"
end

# Add dummy users to all trips as members for testing
# Add to planning trip
planning_trip = test_user.trips.find_by(name: "Summer Cabin Retreat 2025")
if planning_trip
  planning_trip.add_member(alice, role: 'admin') unless planning_trip.has_member?(alice)
  planning_trip.add_member(bob, role: 'member') unless planning_trip.has_member?(bob)
  planning_trip.add_member(charlie, role: 'member') unless planning_trip.has_member?(charlie)
end

# Add to weekend trip
weekend_trip = test_user.trips.find_by(name: "Weekend Adventure")
if weekend_trip
  weekend_trip.add_member(alice, role: 'admin') unless weekend_trip.has_member?(alice)
  weekend_trip.add_member(bob, role: 'member') unless weekend_trip.has_member?(bob)
  weekend_trip.add_member(charlie, role: 'member') unless weekend_trip.has_member?(charlie)

  # Create sample expenses for testing
  unless weekend_trip.expenses.exists?
    # Dinner expense - everyone participated
    dinner_expense = weekend_trip.expenses.create!(
      payer: test_user,
      amount: 84.50,
      description: "Group dinner at Pizza Palace",
      category: "food",
      expense_date: weekend_trip.start_date,
      currency: "EUR"
    )
    dinner_expense.split_equally_among([test_user, alice, bob, charlie])

    # Gas expense - only test_user and bob participated
    gas_expense = weekend_trip.expenses.create!(
      payer: bob,
      amount: 45.20,
      description: "Gas for the drive",
      category: "transport",
      expense_date: weekend_trip.start_date,
      currency: "EUR"
    )
    gas_expense.split_equally_among([test_user, bob])

    # Hotel expense - alice paid for herself and charlie only
    hotel_expense = weekend_trip.expenses.create!(
      payer: alice,
      amount: 120.00,
      description: "Hotel room for Saturday night",
      category: "accommodation",
      expense_date: weekend_trip.start_date,
      currency: "EUR"
    )
    hotel_expense.split_equally_among([alice, charlie])

    # Activity expense - everyone except charlie
    activity_expense = weekend_trip.expenses.create!(
      payer: charlie,
      amount: 75.00,
      description: "Mini golf and arcade games",
      category: "activities",
      expense_date: weekend_trip.start_date + 1.day,
      currency: "EUR"
    )
    activity_expense.split_equally_among([test_user, alice, bob])
  end
end

# Load food items database
load Rails.root.join('db', 'seeds', 'food_items.rb')

# Load public recipes database
load Rails.root.join('db', 'seeds', 'public_recipes.rb')

puts "Created test user: test@example.com / password123"
puts "Created dummy users: alice@example.com, bob@example.com, charlie@example.com (all with password123)"
puts "Added sample expenses to Weekend Adventure trip for testing expense splitting"
