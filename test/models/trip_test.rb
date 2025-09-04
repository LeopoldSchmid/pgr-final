require "test_helper"

class TripTest < ActiveSupport::TestCase
  def setup
    @user = users(:owner)
    @member = users(:member)
    @trip = trips(:planning)
  end

  test "should calculate total expenses correctly" do
    # Create some test expenses
    expense1 = @trip.expenses.create!(
      amount: 50.0,
      description: "Lunch",
      category: "food",
      payer: @user,
      currency: "EUR"
    )
    expense2 = @trip.expenses.create!(
      amount: 30.0,
      description: "Coffee",
      category: "food", 
      payer: @member,
      currency: "EUR"
    )
    
    assert_equal 80.0, @trip.total_expenses
  end

  test "should group expenses by category correctly" do
    # Create expenses in different categories
    @trip.expenses.create!(
      amount: 50.0,
      description: "Dinner",
      category: "food",
      payer: @user,
      currency: "EUR"
    )
    @trip.expenses.create!(
      amount: 100.0,
      description: "Hotel",
      category: "accommodation",
      payer: @user,
      currency: "EUR"
    )
    @trip.expenses.create!(
      amount: 25.0,
      description: "Snacks",
      category: "food",
      payer: @member,
      currency: "EUR"
    )
    
    by_category = @trip.expenses_by_category
    assert_equal 75.0, by_category["food"]
    assert_equal 100.0, by_category["accommodation"]
  end

  test "should calculate user balance correctly" do
    # User pays 100, owes 50 (from split) -> balance +50
    expense = @trip.expenses.create!(
      amount: 100.0,
      description: "Dinner",
      category: "food",
      payer: @user,
      currency: "EUR"
    )
    
    # Split equally between user and member
    expense.split_equally_among([@user, @member])
    
    # User paid 100, owes 50 -> balance +50
    assert_equal 50.0, @trip.user_balance(@user)
    
    # Member paid 0, owes 50 -> balance -50
    assert_equal -50.0, @trip.user_balance(@member)
  end

  test "should generate settlement suggestions correctly" do
    # Create expense where one person pays for everyone
    expense = @trip.expenses.create!(
      amount: 100.0,
      description: "Dinner for everyone",
      category: "food",
      payer: @user,
      currency: "EUR"
    )
    
    # Split equally among all members
    all_members = [@user, @member]
    expense.split_equally_among(all_members)
    
    suggestions = @trip.settlement_suggestions
    assert_not_empty suggestions
    
    # Member should owe user 50
    suggestion = suggestions.first
    assert_equal @member, suggestion[:from]
    assert_equal @user, suggestion[:to]
    assert_equal 50.0, suggestion[:amount]
    assert_equal "EUR", suggestion[:currency]
  end

  test "should handle complex settlement scenarios" do
    # User pays for 60 EUR dinner, member pays for 40 EUR lunch
    # Both expenses split equally
    
    dinner = @trip.expenses.create!(
      amount: 60.0,
      description: "Dinner",
      category: "food",
      payer: @user,
      currency: "EUR"
    )
    dinner.split_equally_among([@user, @member])
    
    lunch = @trip.expenses.create!(
      amount: 40.0,
      description: "Lunch", 
      category: "food",
      payer: @member,
      currency: "EUR"
    )
    lunch.split_equally_among([@user, @member])
    
    # User: paid 60, owes 50 -> +10 balance
    # Member: paid 40, owes 50 -> -10 balance
    assert_equal 10.0, @trip.user_balance(@user)
    assert_equal -10.0, @trip.user_balance(@member)
    
    suggestions = @trip.settlement_suggestions
    assert_equal 1, suggestions.length
    
    suggestion = suggestions.first
    assert_equal @member, suggestion[:from]
    assert_equal @user, suggestion[:to] 
    assert_equal 10.0, suggestion[:amount]
  end

  test "should return zero balance for non-member" do
    non_member = User.create!(email_address: "nonmember@test.com", password: "password")
    assert_equal 0, @trip.user_balance(non_member)
  end

  test "should check if user can manage expenses" do
    # Trip owner should always be able to manage expenses
    assert @trip.user_can_manage_expenses?(@user)
    
    # Regular member permissions depend on trip_member role
    # This would need to be tested based on your trip_member model implementation
  end
end