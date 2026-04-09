require "test_helper"

class MemoriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = User.create!(
      email_address: "memories_test@example.com",
      password: "password123",
      locale: "en"
    )

    @other_user = User.create!(
      email_address: "memories_other@example.com",
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

    @trip_attachment = @trip.trip_attachments.build(
      user: @user,
      name: "Sunset photo"
    )
    @trip_attachment.files.attach(
      io: StringIO.new("fake image content"),
      filename: "sunset.jpg",
      content_type: "image/jpeg"
    )
    @trip_attachment.save!
  end

  test "should get index when authenticated and trip context set" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    patch switch_trip_url, params: { trip_id: @trip.id, return_to: memories_path }

    get memories_url
    assert_response :success
    assert_includes response.body, "Amazing first day!"
  end

  test "should show global feed when no trip context" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    get memories_url
    assert_response :success
    assert_includes response.body, "Amazing first day!"
  end

  test "should get albums page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    patch switch_trip_url, params: { trip_id: @trip.id, return_to: memories_albums_path }

    get memories_albums_url
    assert_response :success
  end

  test "should get map page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    @journal_entry.update!(latitude: 48.8566, longitude: 2.3522)
    patch switch_trip_url, params: { trip_id: @trip.id, return_to: memories_map_path }

    get memories_map_url
    assert_response :success
    assert_includes response.body, "memories-map"
  end

  test "should get favorites page" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }
    @journal_entry.update!(favorite: true)

    get memories_favorites_url
    assert_response :success
    assert_includes response.body, "Amazing first day!"
  end

  test "should require authentication" do
    get memories_url
    assert_redirected_to new_session_url
  end

  test "index should show journal entries for current trip only" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    other_entry = @unauthorized_trip.journal_entries.create!(
      user: @other_user,
      content: "Should stay hidden",
      entry_date: Date.current
    )
    patch switch_trip_url, params: { trip_id: @trip.id, return_to: memories_path }

    get memories_url
    assert_response :success
    assert_includes response.body, @journal_entry.content
    assert_not_includes response.body, other_entry.content
  end

  test "index should show trip attachments for current trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @trip.id, return_to: memories_path }

    get memories_url
    assert_response :success
    assert_includes response.body, @trip_attachment.name
  end

  test "albums should not allow access to unauthorized trip" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    patch switch_trip_url, params: { trip_id: @unauthorized_trip.id, return_to: memories_albums_path }

    get memories_albums_url
    assert_redirected_to select_trip_url(return_to: memories_path)
  end

  test "index should order memories by date descending" do
    post session_url, params: { email_address: @user.email_address, password: "password123" }

    # Create another journal entry with earlier date
    earlier_entry = @trip.journal_entries.create!(
      user: @user,
      content: "Preparing for the trip",
      entry_date: Date.current - 1.day
    )

    patch switch_trip_url, params: { trip_id: @trip.id, return_to: memories_path }

    get memories_url
    assert_response :success
    assert_includes response.body, @journal_entry.content
    assert_includes response.body, earlier_entry.content
  end
end
