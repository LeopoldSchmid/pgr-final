require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
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

    @trip = Trip.create!(
      user: @user,
      name: "Test Trip",
      status: "planning",
      start_date: Date.current + 10.days
    )

    @unauthorized_trip = Trip.create!(
      user: @other_user,
      name: "Other Trip",
      status: "planning"
    )

    # Create some planning data
    @date_proposal = @trip.date_proposals.create!(
      proposed_by: @user,
      start_date: Date.current + 10.days,
      end_date: Date.current + 15.days
    )

    @discussion = @trip.discussions.create!(
      title: "Planning Discussion",
      content: "Let's discuss the trip",
      user: @user
    )

    @shopping_list = @trip.shopping_lists.create!(
      name: "Trip Supplies"
    )
  end

  test "should get index when authenticated and trip context set" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    # Set trip context
    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get plans_url
    assert_response :success
  end

  test "should redirect to trip selection when no trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_url
    assert_redirected_to select_trip_url
  end

  test "should require authentication" do
    get plans_url
    assert_redirected_to new_session_url
  end

  test "index should show date proposals for current trip only" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get plans_url
    assert_response :success
    assert_select "h2", text: /Date Proposals/i
  end

  test "index should show discussions for current trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get plans_url
    assert_response :success
  end

  test "index should show shopping lists for current trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get plans_url
    assert_response :success
  end

  test "should not allow access to unauthorized trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    session[:current_trip_id] = @unauthorized_trip.id

    get plans_url
    assert_redirected_to select_trip_url
  end
end
