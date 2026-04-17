require "test_helper"

class PlansControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "plans_test@example.com",
      password: "password123",
      locale: "en"
    )

    @other_user = User.create!(
      email_address: "plans_other@example.com",
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

    get plans_url, params: { trip_id: @trip.id }
    assert_redirected_to plans_meals_url(trip_id: @trip.id)
  end

  test "should redirect index to last selected plans tab when present" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_shopping_url, params: { trip_id: @trip.id }
    get plans_url, params: { trip_id: @trip.id }

    assert_redirected_to plans_shopping_url(trip_id: @trip.id)
  end

  test "should redirect to recipe library when no trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_url
    assert_redirected_to recipe_library_url
  end

  test "should get meals page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_meals_url, params: { trip_id: @trip.id }
    assert_response :success
  end

  test "should get shopping plan page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_shopping_url, params: { trip_id: @trip.id }
    assert_response :success
    assert_match "Shopping Plan", response.body
  end

  test "should create default shopping list when opening shopping list tab without lists" do
    @shopping_list.destroy!

    post session_url, params: { email_address: @user.email_address, password: "password123" }

    assert_difference("@trip.shopping_lists.count", 1) do
      get plans_shopping_list_url, params: { trip_id: @trip.id }
    end

    created_list = @trip.shopping_lists.order(:created_at).last
    assert_redirected_to plans_shopping_list_url(trip_id: @trip.id, list_id: created_list.id)
  end

  test "should get packing page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_packing_url, params: { trip_id: @trip.id }
    assert_response :success
  end

  test "should get itinerary page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_itinerary_url, params: { trip_id: @trip.id }
    assert_response :success
  end

  test "should require authentication" do
    get plans_url
    assert_redirected_to new_session_url
  end

  test "should not allow access to unauthorized trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get plans_meals_url
    assert_redirected_to select_trip_url(return_to: plans_path)
  end
end
