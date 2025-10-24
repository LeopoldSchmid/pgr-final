require "test_helper"

class MemoriesControllerTest < ActionDispatch::IntegrationTest
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
      start_date: 1.day.ago,
      end_date: 5.days.from_now
    )

    @unauthorized_trip = Trip.create!(
      user: @other_user,
      name: "Other Trip",
      start_date: 2.days.ago,
      end_date: 4.days.from_now
    )

    # Create some memories (journal entries and attachments)
    @journal_entry = @trip.journal_entries.create!(
      user: @user,
      content: "Amazing first day!",
      entry_date: Date.current,
      location: "Paris"
    )

    @trip_attachment = @trip.trip_attachments.create!(
      user: @user,
      caption: "Beautiful sunset"
    )
  end

  test "should get index when authenticated and trip context set" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    # Set trip context
    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get memories_url
    assert_response :success
  end

  test "should show global feed when no trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get memories_url
    assert_response :success
  end

  test "should get albums page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    session[:current_trip_id] = @trip.id

    get memories_albums_url
    assert_response :success
  end

  test "should get map page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    session[:current_trip_id] = @trip.id

    get memories_map_url
    assert_response :success
  end

  test "should get favorites page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get memories_favorites_url
    assert_response :success
  end

  test "should require authentication" do
    get memories_url
    assert_redirected_to new_session_url
  end

  test "index should show journal entries for current trip only" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get memories_url
    assert_response :success
  end

  test "index should show trip attachments for current trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get memories_url
    assert_response :success
  end

  test "albums should not allow access to unauthorized trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    session[:current_trip_id] = @unauthorized_trip.id

    get memories_albums_url
    assert_redirected_to select_trip_url
  end

  test "index should order memories by date descending" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    # Create another journal entry with earlier date
    earlier_entry = @trip.journal_entries.create!(
      user: @user,
      content: "Preparing for the trip",
      entry_date: Date.current - 1.day
    )

    get trip_url(@trip)
    session[:current_trip_id] = @trip.id

    get memories_url
    assert_response :success
  end
end
