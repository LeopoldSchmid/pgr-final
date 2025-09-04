require "test_helper"

class ExpenseTest < ActiveSupport::TestCase
  def setup
    @user = users(:owner)
    @member = users(:member)
    @trip = trips(:planning)
    @expense = expenses(:lunch)
  end

  test "should be valid" do
    assert @expense.valid?
  end

  test "should require amount" do
    @expense.amount = nil
    assert_not @expense.valid?
    assert_includes @expense.errors[:amount], "can't be blank"
  end

  test "should require positive amount" do
    @expense.amount = -10.0
    assert_not @expense.valid?
    assert_includes @expense.errors[:amount], "must be greater than 0"
  end

  test "should require description" do
    @expense.description = nil
    assert_not @expense.valid?
    assert_includes @expense.errors[:description], "can't be blank"
  end

  test "should require valid category" do
    @expense.category = "invalid_category"
    assert_not @expense.valid?
    assert_includes @expense.errors[:category], "is not included in the list"
  end

  test "should accept valid categories" do
    valid_categories = %w[food accommodation transport activities shopping other]
    valid_categories.each do |category|
      @expense.category = category
      assert @expense.valid?, "#{category} should be a valid category"
    end
  end

  test "should split equally among users" do
    users = [@user, @member]
    @expense.split_equally_among(users)
    
    assert_equal 2, @expense.expense_participants.count
    
    expected_amount = (@expense.amount / 2).round(2)
    @expense.expense_participants.each do |participant|
      assert_equal expected_amount, participant.amount_owed
    end
  end

  test "should handle remainder when splitting equally" do
    @expense.amount = 10.01  # Will create remainder when split between 2
    users = [@user, @member]
    @expense.split_equally_among(users)
    
    amounts = @expense.expense_participants.pluck(:amount_owed)
    assert_equal @expense.amount, amounts.sum
    
    # First participant should get the remainder
    first_participant = @expense.expense_participants.first
    assert_equal 5.01, first_participant.amount_owed
  end

  test "should calculate total participants amount correctly" do
    @expense.split_equally_among([@user, @member])
    assert_equal @expense.amount, @expense.total_participants_amount
  end

  test "should format amount correctly" do
    @expense.amount = 25.5
    @expense.currency = "EUR"
    assert_equal "25.50 EUR", @expense.formatted_amount
    assert_equal "25.50", @expense.formatted_amount(with_currency: false)
  end

  test "should return category emoji" do
    @expense.category = "food"
    assert_equal "🍽️", @expense.category_emoji
    
    @expense.category = "transport"
    assert_equal "🚗", @expense.category_emoji
    
    @expense.category = "other"
    assert_equal "💰", @expense.category_emoji
  end

  test "should clear existing participants when splitting" do
    # Create initial participants
    @expense.split_equally_among([@user])
    assert_equal 1, @expense.expense_participants.count
    
    # Split among different users should clear old participants
    @expense.split_equally_among([@member])
    assert_equal 1, @expense.expense_participants.count
    assert_equal @member.id, @expense.expense_participants.first.user_id
  end

  test "should handle location data" do
    @expense.latitude = 40.7128
    @expense.longitude = -74.0060
    @expense.location = "New York"
    
    assert @expense.has_location?
    assert_equal [40.7128, -74.0060], @expense.coordinates
    assert_equal "New York", @expense.location_name
  end

  test "should handle missing location" do
    @expense.latitude = nil
    @expense.longitude = nil
    @expense.location = nil
    
    assert_not @expense.has_location?
    assert_nil @expense.coordinates
    assert_equal "Unknown location", @expense.location_name
  end
end