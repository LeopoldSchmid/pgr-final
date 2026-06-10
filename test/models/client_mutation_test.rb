require "test_helper"

class ClientMutationTest < ActiveSupport::TestCase
  fixtures :users, :trips

  setup do
    @trip = trips(:planning)
    @actor = users(:owner)
  end

  test "client uuid is unique within trip" do
    @trip.client_mutations.create!(
      actor: @actor,
      client_uuid: "abc-123",
      mutation_type: "expense_create",
      payload_hash: "hash-1"
    )

    duplicate = @trip.client_mutations.build(
      actor: @actor,
      client_uuid: "abc-123",
      mutation_type: "expense_create",
      payload_hash: "hash-1"
    )

    assert_not duplicate.valid?
    assert_includes duplicate.errors[:client_uuid], "has already been taken"
  end

  test "detects duplicate payload hash" do
    mutation = @trip.client_mutations.create!(
      actor: @actor,
      client_uuid: "abc-123",
      mutation_type: "expense_create",
      payload_hash: "hash-1"
    )

    assert mutation.duplicate_of_payload?("hash-1")
    assert_not mutation.duplicate_of_payload?("hash-2")
  end
end
