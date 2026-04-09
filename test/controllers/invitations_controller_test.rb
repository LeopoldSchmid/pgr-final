require "test_helper"

class InvitationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email_address: "invitation_owner@example.com",
      password: "password123",
      locale: "en"
    )

    @invitee = User.create!(
      email_address: "invitee@example.com",
      password: "password123",
      locale: "en"
    )

    @wrong_user = User.create!(
      email_address: "wrong_invitee@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @owner,
      name: "Invitation Test Trip",
      start_date: 2.weeks.from_now,
      end_date: 3.weeks.from_now
    )

    @invitation = @trip.invitations.create!(
      email: @invitee.email_address,
      invited_by: @owner,
      role: "member"
    )
  end

  test "owner can create invitation" do
    post session_url, params: { email_address: @owner.email_address, password: "password123" }

    assert_difference("Invitation.count", 1) do
      post trip_invitations_url(trip_id: @trip.id), params: {
        invitation: {
          email: "new_invitee@example.com",
          role: "guest"
        }
      }
    end

    created_invitation = Invitation.order(:created_at).last
    assert_equal "new_invitee@example.com", created_invitation.email
    assert_equal @owner, created_invitation.invited_by
    assert_redirected_to trip_invitations_url(trip_id: @trip.id)
  end

  test "show redirects unauthenticated existing user to sign in" do
    get invitation_url(@invitation.token)

    assert_redirected_to new_session_url
  end

  test "show redirects unauthenticated new user to registration" do
    invitation = @trip.invitations.create!(
      email: "fresh_invitee@example.com",
      invited_by: @owner,
      role: "member"
    )

    get invitation_url(invitation.token)

    assert_redirected_to new_registration_url(email: invitation.email)
  end

  test "show returns forbidden for signed in wrong user" do
    post session_url, params: { email_address: @wrong_user.email_address, password: "password123" }

    get invitation_url(@invitation.token)

    assert_response :forbidden
  end

  test "sign in after invitation redirects through accept flow and joins trip" do
    get invitation_url(@invitation.token)
    assert_redirected_to new_session_url

    post session_url, params: { email_address: @invitee.email_address, password: "password123" }
    assert_redirected_to accept_invitation_url(@invitation.token, locale: "en")

    follow_redirect!
    assert_redirected_to trip_url(@trip)

    @invitation.reload
    assert_equal "accepted", @invitation.status
    assert @trip.has_member?(@invitee)
  end

  test "registration after invitation accepts invitation and joins trip" do
    invitation = @trip.invitations.create!(
      email: "brand_new_invitee@example.com",
      invited_by: @owner,
      role: "member"
    )

    get invitation_url(invitation.token)
    assert_redirected_to new_registration_url(email: invitation.email)

    assert_difference("User.count", 1) do
      post registrations_url, params: {
        user: {
          email_address: invitation.email,
          password: "password123",
          password_confirmation: "password123"
        }
      }
    end

    invitation.reload
    created_user = User.find_by!(email_address: invitation.email)

    assert_equal "accepted", invitation.status
    assert @trip.has_member?(created_user)
    assert_redirected_to trip_url(@trip)
  end

  test "accept redirects signed in wrong user back to invitation" do
    post session_url, params: { email_address: @wrong_user.email_address, password: "password123" }

    patch accept_invitation_url(@invitation.token)

    assert_redirected_to invitation_url(@invitation.token, locale: "en")
    @invitation.reload
    assert_equal "pending", @invitation.status
  end

  test "decline marks invitation declined" do
    patch decline_invitation_url(@invitation.token)

    assert_redirected_to user_invitations_url(locale: "en")
    @invitation.reload
    assert_equal "declined", @invitation.status
  end
end
