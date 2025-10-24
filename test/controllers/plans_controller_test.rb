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
      start_date: Date.current + 10.days,
      end_date: Date.current + 15.days
    )

    @unauthorized_trip = Trip.create!(
      user: @other_user,
      name: "Other Trip",
      start_date: Date.current + 20.days,
      end_date: Date.current + 25.days
    )

    # Create some planning data
    @date_proposal = @trip.date_proposals.create!(
      user: @user,
      start_date: Date.current + 10.days,
      end_date: Date.current + 15.days
    )

    @discussion = @trip.discussions.create!(
      title: "Planning Discussion",
      content: "Let's discuss the trip",
      user: @user
    ) rescue nil # Skip if discussions don't exist yet

    @shopping_list = @trip.shopping_lists.create!(
      name: "Trip Supplies"
    )
  end

  test "should redirect index to meals when authenticated and trip context set" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    # Set trip context
    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get plans_url
    assert_redirected_to plans_meals_url
  end

  test "should redirect to recipe library when no trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_url
    assert_redirected_to recipe_library_url
  end

  test "should get meals page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    session[:current_trip_id] = @trip.id

    get plans_meals_url
    assert_response :success
  end

  test "should get shopping page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    session[:current_trip_id] = @trip.id

    get plans_shopping_url
    assert_response :success
  end

  test "should get packing page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    session[:current_trip_id] = @trip.id

    get plans_packing_url
    assert_response :success
  end

  test "should get itinerary page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    session[:current_trip_id] = @trip.id

    get plans_itinerary_url
    assert_response :success
  end

  test "should require authentication" do
    get plans_url
    assert_redirected_to new_session_url
  end

  test "should not allow access to unauthorized trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    session[:current_trip_id] = @unauthorized_trip.id

    get plans_meals_url
    assert_redirected_to select_trip_url
  end
end
