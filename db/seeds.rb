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
  test_user.trips.create!(
    name: "Summer Cabin Retreat 2025",
    description: "Weekend getaway to the mountains with college friends. Planning to cook together, hike, and relax by the lake.",
    status: "planning",
    start_date: 3.months.from_now.to_date,
    end_date: 3.months.from_now.to_date + 3.days
  )

  # Active trip
  test_user.trips.create!(
    name: "City Food Tour",
    description: "Exploring local restaurants and food markets downtown.",
    status: "active",
    start_date: 1.day.ago.to_date,
    end_date: 2.days.from_now.to_date
  )

  # Completed trip
  test_user.trips.create!(
    name: "Beach House Week",
    description: "Amazing week at the coast with family. Cooked fresh seafood every night!",
    status: "completed",
    start_date: 2.months.ago.to_date,
    end_date: 2.months.ago.to_date + 6.days
  )

  puts "Created sample trips for navigation demo"
end

puts "Created test user: test@example.com / password123"
