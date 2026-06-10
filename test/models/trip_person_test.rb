require "test_helper"

class TripPersonTest < ActiveSupport::TestCase
  fixtures :users, :trips

  setup do
    @trip = trips(:planning)
    @user = users(:owner)
  end

  test "find_or_create_for_user creates linked trip person" do
    trip_person = TripPerson.find_or_create_for_user!(trip: @trip, user: @user)

    assert_equal @trip, trip_person.trip
    assert_equal @user, trip_person.user
    assert_equal "owner", trip_person.display_name
    assert_equal @user.email_address, trip_person.email
    assert_equal "active", trip_person.status
  end

  test "placeholder person can exist without user" do
    trip_person = @trip.trip_people.create!(display_name: "Max", status: "placeholder")

    assert_nil trip_person.user
    assert_equal "Max", trip_person.display_name
    assert_equal "placeholder", trip_person.status
  end

  test "link_user updates pending person while preserving identity" do
    pending = @trip.trip_people.create!(display_name: "Max", email: "max@example.com", status: "invited")
    user = User.create!(email_address: "max@example.com", password: "password")

    assert_no_difference("TripPerson.count") do
      pending.link_user!(user)
    end

    assert_equal user, pending.user
    assert_equal "active", pending.status
    assert_equal "Max", pending.display_name
  end
end
