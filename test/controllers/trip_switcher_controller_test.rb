require "test_helper"

class TripSwitcherControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      locale: "en"
    )

    @other_user = User.create!(
      email_address: "other@example.com",
      password: "password123",
      locale: "en"
    )

    @trip1 = Trip.create!(
      user: @user,
      name: "Trip 1",
      status: "planning"
    )

    @trip2 = Trip.create!(
      user: @user,
      name: "Trip 2",
      status: "active"
    )

    @member_trip = Trip.create!(
      user: @other_user,
      name: "Member Trip",
      status: "planning"
    )
    @member_trip.add_member(@user)

    @unauthorized_trip = Trip.create!(
      user: @other_user,
      name: "Unauthorized Trip",
      status: "planning"
    )
  end

  test "should get index when authenticated" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get select_trip_url
    assert_response :success
  end

  test "should require authentication for index" do
    get select_trip_url
    assert_redirected_to new_session_url
  end

  test "index should show all user trips (owned and member)" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get select_trip_url
    assert_response :success
  end

  test "should switch to selected trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @trip1.id }
    assert_equal @trip1.id, session[:current_trip_id]
  end

  test "should redirect after switching trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @trip1.id, return_to: plans_path }
    assert_redirected_to plans_path
  end

  test "should redirect to trip page by default after switching" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @trip1.id }
    assert_redirected_to trip_path(@trip1)
  end

  test "should not allow switching to unauthorized trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @unauthorized_trip.id }
    assert_redirected_to select_trip_url
    assert_nil session[:current_trip_id]
    assert_equal "You don't have access to this trip.", flash[:alert]
  end

  test "should allow switching to member trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @member_trip.id }
    assert_equal @member_trip.id, session[:current_trip_id]
  end

  test "should clear trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    # First set a trip
    session[:current_trip_id] = @trip1.id

    # Then clear it
    delete clear_trip_context_url
    assert_nil session[:current_trip_id]
  end

  test "should redirect to home after clearing trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    session[:current_trip_id] = @trip1.id

    delete clear_trip_context_url
    assert_redirected_to root_path
  end
end
