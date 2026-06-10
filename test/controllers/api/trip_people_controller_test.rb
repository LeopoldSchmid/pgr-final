require "test_helper"

class Api::TripPeopleControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :trips

  setup do
    @user = users(:owner)
    @trip = Trip.create!(user: @user, name: "People API Trip")
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  test "creates placeholder trip person" do
    assert_difference("TripPerson.count", 1) do
      post api_trip_trip_people_url(@trip), params: {
        trip_person: {
          display_name: "Max",
          status: "placeholder"
        }
      }
    end

    assert_response :created
    assert_equal "Max", JSON.parse(response.body).fetch("display_name")
  end

  test "links trip person to user" do
    person = @trip.trip_people.create!(display_name: "Guest", status: "invited")
    linked_user = User.create!(email_address: "linked@example.com", password: "password")

    patch link_user_api_trip_trip_person_url(@trip, person), params: {
      trip_person: { user_id: linked_user.id }
    }

    assert_response :success
    assert_equal linked_user, person.reload.user
    assert @trip.expense_events.exists?(event_type: "trip_person_linked")
  end

  test "merges duplicate trip person" do
    source = @trip.trip_people.create!(display_name: "Duplicate", status: "placeholder")
    target = @trip.trip_person_for(@user)

    post merge_api_trip_trip_person_url(@trip, source), params: {
      trip_person: { target_trip_person_id: target.id }
    }

    assert_response :success
    assert_equal "archived", source.reload.status
  end
end
