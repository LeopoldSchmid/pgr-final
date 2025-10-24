require "test_helper"

class TripsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "test@example.com",
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

    sign_in_as(@user)
  end

  test "should get overview" do
    get trip_overview_url(trip_id: @trip.id), params: { locale: :en }
    assert_response :success
  end

  test "should get details" do
    get trip_details_url(trip_id: @trip.id), params: { locale: :en }
    assert_response :success
  end

  test "should get participants" do
    get trip_participants_url(trip_id: @trip.id), params: { locale: :en }
    assert_response :success
  end

  test "old plan route redirects to overview" do
    get trip_plan_context_url(trip_id: @trip.id), params: { locale: :en }
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
