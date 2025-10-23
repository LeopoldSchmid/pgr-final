require "test_helper"

class NavigationHelperTest < ActionView::TestCase
  include NavigationHelper

  def setup
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @user,
      name: "My Test Trip",
      start_date: 1.month.from_now,
      end_date: 1.month.from_now + 5.days
    )

    sign_in_as(@user)
  end

  test "active_nav_class returns active class for home when on root path" do
    def current_page?(path)
      path == root_path
    end

    assert_includes active_nav_class(:home), "text-primary-accent"
  end

  test "active_nav_class returns inactive class for home when not on root path" do
    def current_page?(path)
      false
    end

    assert_includes active_nav_class(:home), "text-text-primary/70"
  end

  test "trip_context_display returns trip name when current_trip is set" do
    def current_trip
      @trip
    end

    assert_equal "My Test Trip", trip_context_display
  end

  test "trip_context_display returns app name when no current_trip" do
    def current_trip
      nil
    end

    assert_equal I18n.t('app_name'), trip_context_display
  end

  test "scoped_feature_path for home returns root_path" do
    assert_equal root_path, scoped_feature_path(:home)
  end

  test "scoped_feature_path for trip returns trip_path when current_trip exists" do
    def current_trip
      @trip
    end

    assert_equal trip_path(@trip.id), scoped_feature_path(:trip)
  end

  test "scoped_feature_path for trip returns new_trip_path when no trips" do
    def current_trip
      nil
    end

    def current_trip_or_next
      nil
    end

    assert_equal new_trip_path, scoped_feature_path(:trip)
  end

  test "scoped_feature_path for plans returns plans_path when current_trip exists" do
    def current_trip
      @trip
    end

    assert_equal plans_path, scoped_feature_path(:plans)
  end

  test "show_back_button? returns false on root path" do
    def current_page?(path)
      path == root_path
    end

    def authenticated?
      true
    end

    assert_not show_back_button?
  end

  test "show_back_button? returns true when not on root path and authenticated" do
    def current_page?(path)
      false
    end

    def authenticated?
      true
    end

    assert show_back_button?
  end

  test "back_path returns trip_path when current_trip is set" do
    def current_trip
      @trip
    end

    assert_equal trip_path(@trip.id), back_path
  end

  test "back_path returns root_path when no current_trip" do
    def current_trip
      nil
    end

    assert_equal root_path, back_path
  end

  test "nav_icon_for returns appropriate icon path for each section" do
    assert_not_nil nav_icon_for(:home)
    assert_not_nil nav_icon_for(:trip)
    assert_not_nil nav_icon_for(:plans)
    assert_not_nil nav_icon_for(:memories)
    assert_not_nil nav_icon_for(:expenses)
  end

  test "pending_invitations_count returns correct count" do
    # Create a different email so it's not already a member
    Invitation.create!(
      trip: @trip,
      email: "invite@example.com",
      status: "pending",
      invited_by: @user,
      token: SecureRandom.hex(10),
      expires_at: 7.days.from_now
    )

    def authenticated?
      true
    end

    # Mock the Current.user.email_address to match the invitation
    def Current.user
      @mock_user ||= Struct.new(:email_address).new("invite@example.com")
    end

    # Since we changed the email, this should return 1
    assert_equal 1, pending_invitations_count
  end

  test "pending_invitations_count returns 0 when not authenticated" do
    def authenticated?
      false
    end

    assert_equal 0, pending_invitations_count
  end
end
