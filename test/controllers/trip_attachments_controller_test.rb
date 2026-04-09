require "test_helper"

class TripAttachmentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @owner = User.create!(
      email_address: "attachments_owner@example.com",
      password: "password123",
      locale: "en"
    )

    @member = User.create!(
      email_address: "attachments_member@example.com",
      password: "password123",
      locale: "en"
    )

    @outsider = User.create!(
      email_address: "attachments_outsider@example.com",
      password: "password123",
      locale: "en"
    )

    @trip = Trip.create!(
      user: @owner,
      name: "Attachment Test Trip",
      start_date: 1.week.from_now,
      end_date: 2.weeks.from_now
    )
    @trip.add_member(@member)

    @attachment = @trip.trip_attachments.build(
      user: @owner,
      name: "Existing memory"
    )
    @attachment.files.attach(uploaded_file("existing.jpg"))
    @attachment.save!
  end

  test "member can upload attachment files" do
    post session_url, params: { email_address: @member.email_address, password: "password123" }

    assert_difference("TripAttachment.count", 1) do
      post trip_trip_attachments_url(trip_id: @trip.id), params: {
        trip_attachment: {
          name: "Beach day",
          files: [ uploaded_file("beach.jpg"), uploaded_file("receipt.pdf", "application/pdf") ]
        }
      }
    end

    created_attachment = TripAttachment.order(:created_at).last
    assert_equal "Beach day", created_attachment.name
    assert_equal @member, created_attachment.user
    assert_equal 2, created_attachment.files.count
    assert_redirected_to plan_trip_url(@trip)
  end

  test "upload failure redirects back with alert" do
    post session_url, params: { email_address: @owner.email_address, password: "password123" }

    assert_no_difference("TripAttachment.count") do
      post trip_trip_attachments_url(trip_id: @trip.id), params: {
        trip_attachment: {
          name: "",
          files: []
        }
      }
    end

    assert_redirected_to plan_trip_url(@trip)
  end

  test "outsider cannot upload attachment" do
    post session_url, params: { email_address: @outsider.email_address, password: "password123" }

    assert_no_difference("TripAttachment.count") do
      post trip_trip_attachments_url(trip_id: @trip.id), params: {
        trip_attachment: {
          name: "Blocked upload",
          files: [ uploaded_file("blocked.jpg") ]
        }
      }
    end

    assert_redirected_to root_url
  end

  test "owner can rename attachment" do
    post session_url, params: { email_address: @owner.email_address, password: "password123" }

    patch trip_trip_attachment_url(trip_id: @trip.id, id: @attachment.id), params: {
      trip_attachment: { name: "Renamed memory" }
    }

    assert_redirected_to plan_trip_url(@trip)
    @attachment.reload
    assert_equal "Renamed memory", @attachment.name
  end

  test "owner can delete attachment" do
    post session_url, params: { email_address: @owner.email_address, password: "password123" }

    assert_difference("TripAttachment.count", -1) do
      delete trip_trip_attachment_url(trip_id: @trip.id, id: @attachment.id)
    end

    assert_redirected_to plan_trip_url(@trip)
  end

  private

  def uploaded_file(filename, content_type = "image/jpeg")
    file = Tempfile.new([ File.basename(filename, ".*"), File.extname(filename) ])
    file.binmode
    file.write("test-upload-content")
    file.rewind

    Rack::Test::UploadedFile.new(file.path, content_type, true, original_filename: filename)
  end
end
