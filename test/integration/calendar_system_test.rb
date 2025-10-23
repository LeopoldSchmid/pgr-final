require 'test_helper'

class CalendarSystemTest < ActionDispatch::IntegrationTest
  def setup
    @user = User.create!(
      email_address: "test@example.com",
      password: "password123",
      password_confirmation: "password123"
    )
    
    @trip = Trip.create!(
      name: "Test Trip",
      description: "A test trip for calendar functionality",
      user: @user,
      start_date: 1.month.from_now,
      end_date: 1.month.from_now + 7.days
    )
    
    login_as(@user)
  end

  test "can access date proposals calendar page" do
    get trip_date_proposals_path(@trip)
    assert_response :success
    assert_select "h1", "Date Planning Calendar"
    assert_select "[data-controller='calendar']"
  end

  test "can create date proposal" do
    assert_difference('DateProposal.count', 1) do
      post trip_date_proposals_path(@trip), params: {
        date_proposal: {
          start_date: Date.current + 10.days,
          end_date: Date.current + 15.days,
          description: "Test proposal"
        }
      }
    end
    
    proposal = DateProposal.last
    assert_equal "Test proposal", proposal.description
    assert_redirected_to plan_trip_path(@trip)
  end

  test "can vote on date proposal" do
    proposal = DateProposal.create!(
      trip: @trip,
      user: @user,
      start_date: Date.current + 10.days,
      end_date: Date.current + 15.days
    )

    assert_difference('DateProposalVote.count', 1) do
      post trip_date_proposal_votes_path(@trip), params: {
        date_proposal_vote: {
          date_proposal_id: proposal.id,
          vote_type: 'yes'
        }
      }, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
    end
    
    assert_response :success
    vote = DateProposalVote.last
    assert_equal 'yes', vote.vote_type
  end

  test "can create user availability" do
    assert_difference('UserAvailability.count', 1) do
      post trip_user_availabilities_path(@trip), params: {
        user_availability: {
          start_date: Date.current + 5.days,
          end_date: Date.current + 7.days,
          availability_type: 'unavailable',
          title: 'Work Conference'
        }
      }, headers: { 'X-Requested-With' => 'XMLHttpRequest' }
    end
    
    assert_response :success
    availability = UserAvailability.last
    assert_equal 'unavailable', availability.availability_type
    assert_equal 'Work Conference', availability.title
  end

  test "can fetch calendar events API" do
    # Create test data
    proposal = DateProposal.create!(
      trip: @trip,
      user: @user,
      start_date: Date.current + 10.days,
      end_date: Date.current + 15.days,
      description: "API test proposal"
    )
    
    availability = UserAvailability.create!(
      user: @user,
      start_date: Date.current + 5.days,
      end_date: Date.current + 7.days,
      availability_type: 'unavailable',
      title: 'Test Unavailability'
    )

    get api_trip_calendar_events_path(@trip)
    assert_response :success
    
    events = JSON.parse(response.body)
    assert events.is_a?(Array)
    assert events.any? { |e| e['type'] == 'proposal' }
    assert events.any? { |e| e['type'] == 'unavailable' }
  end

  private

  def login_as(user)
    post session_path, params: { email_address: user.email_address, password: "password123" }
  end
end