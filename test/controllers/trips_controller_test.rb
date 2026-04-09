require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "trips_test@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "Test Trip",
      description: "A test trip",
      start_date: 1.month.from_now,
      end_date: 1.month.from_now + 5.days
    )

    post session_url, params: { email_address: @user.email_address, password: "password123" }
    patch switch_trip_url, params: { trip_id: @trip.id, return_to: trip_overview_path }
  end

  test "should get overview" do
    get trip_overview_url, params: { locale: :en }
    assert_response :success
  end

  test "should get details" do
    get trip_details_url, params: { locale: :en }
    assert_response :success
  end

  test "should get participants" do
    get trip_participants_url, params: { locale: :en }
    assert_response :success
  end

  test "old plan route redirects to overview" do
    get trip_plan_context_url, params: { locale: :en }
    assert_redirected_to trip_overview_url
  end

  test "should update trip details" do
    patch trip_url(@trip, locale: :en), params: {
      trip: {
        name: "Updated Trip Name",
        description: "Updated description"
      }
    }
    assert_redirected_to trip_url(@trip)
    @trip.reload
    assert_equal "Updated Trip Name", @trip.name
  end
end
