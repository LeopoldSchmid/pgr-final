require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
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

  test "should get index" do
    get root_url
    assert_response :success
  end

  test "should get calendar" do
    get home_calendar_url
    assert_response :success
  end

  test "should get upcoming" do
    get home_upcoming_url
    assert_response :success
  end

  test "calendar should show trips with dates" do
    get home_calendar_url
    assert_response :success
    # Calendar events should be loaded in @calendar_events
  end

  test "upcoming should show future trips" do
    get home_upcoming_url
    assert_response :success
    assert_not_nil assigns(:upcoming_trips)
  end
end
