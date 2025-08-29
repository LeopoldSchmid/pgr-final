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

  # Add sample journal entries to the completed trip
  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Arrived at the beach house! The view is absolutely stunning. You can see the ocean from every window. The kids are already asking to go to the beach.",
    location: "Oceanview Beach House",
    entry_date: completed_trip.start_date,
    favorite: true
  )

  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Spent the morning collecting shells with the family. Found some amazing sand dollars. The afternoon was perfect for reading on the deck.",
    location: "Sandy Shore Beach",
    entry_date: completed_trip.start_date + 1.day,
    favorite: false
  )

  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Cooked the most amazing seafood pasta tonight! Fresh mussels and clams from the local market. Everyone said it was restaurant quality. Definitely saving this recipe.",
    location: "Beach House Kitchen",
    entry_date: completed_trip.start_date + 2.days,
    favorite: true
  )

  completed_trip.journal_entries.create!(
    user: test_user,
    content: "Last day at the beach. Watched the sunrise from the deck with coffee. These moments of peace are what I'll remember most. Already planning to come back next year.",
    location: "Beach House Deck",
    entry_date: completed_trip.end_date,
    favorite: true
  )

  puts "Created sample trips and journal entries for testing"
end

puts "Created test user: test@example.com / password123"
