require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  fixtures :users, :trips, :expenses, :expense_participants

  def setup
    @user = users(:owner)
    @member = users(:member)
    @trip = trips(:planning)
    @expense = expenses(:lunch)
    post session_url, params: { email_address: @user.email_address, password: "password" }
  end

  def select_trip_context
    patch switch_trip_url, params: { trip_id: @trip.id, return_to: expenses_path }
  end

  def trip_expenses_index_path
    trip_expenses_path(trip_id: @trip.id)
  end

  def trip_new_expense_path
    new_trip_expense_path(trip_id: @trip.id)
  end

  def trip_edit_expense_path(expense = @expense)
    edit_trip_expense_path(trip_id: @trip.id, id: expense.id)
  end

  def trip_expense_resource_path(expense = @expense)
    trip_expense_path(trip_id: @trip.id, id: expense.id)
  end

  def trip_duplicate_expense_path(expense = @expense)
    duplicate_trip_expense_path(trip_id: @trip.id, id: expense.id)
  end

  test "should get index" do
    select_trip_context
    get trip_expenses_index_path
    assert_response :success
    assert_includes response.body, @trip.name
    assert_includes response.body, @expense.description
  end

  test "should get by_person page" do
    select_trip_context
    get expenses_by_person_url
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "should get by_category page" do
    select_trip_context
    get expenses_by_category_url
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "should get settle page" do
    select_trip_context
    get expenses_settle_url
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "should get summary page" do
    get expenses_summary_url
    assert_response :success
    assert_includes response.body, "Expense Summary"
  end

  test "should redirect context pages when no trip selected" do
    get expenses_by_person_url
    assert_redirected_to select_trip_url(return_to: expenses_path)
  end

  test "should get new" do
    select_trip_context
    get trip_new_expense_path
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy create redirects without creating expense" do
    select_trip_context
    assert_no_difference("Expense.count") do
      post trip_expenses_index_path, params: {
        expense: {
          amount: 50.0,
          description: "Test dinner",
          category: "food",
          expense_date: Date.current,
          currency: "EUR",
          payer_id: @user.id,
          participant_ids: [ @user.id, @member.id ]
        }
      }
    end

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy custom split create redirects without creating expense" do
    select_trip_context
    assert_no_difference("Expense.count") do
      post trip_expenses_index_path, params: {
        expense: {
          amount: 100.0,
          description: "Custom split dinner",
          category: "food",
          expense_date: Date.current,
          currency: "EUR",
          payer_id: @user.id,
          custom_amounts: {
            @user.id.to_s => "60.0",
            @member.id.to_s => "40.0"
          }
        }
      }
    end

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy create with different payer redirects without creating expense" do
    select_trip_context
    assert_no_difference("Expense.count") do
      post trip_expenses_index_path, params: {
        expense: {
          amount: 30.0,
          description: "Member paid",
          category: "food",
          expense_date: Date.current,
          currency: "EUR",
          payer_id: @member.id,
          participant_ids: [ @user.id, @member.id ]
        }
      }
    end

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "should get edit" do
    select_trip_context
    get trip_edit_expense_path
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy update redirects without changing expense" do
    select_trip_context
    original_description = @expense.description
    original_amount = @expense.amount

    patch trip_expense_resource_path, params: {
      expense: {
        amount: 75.0,
        description: "Updated dinner",
        category: "food",
        expense_date: Date.current,
        currency: "EUR",
        payer_id: @user.id,
        participant_ids: [ @user.id, @member.id ]
      }
    }

    @expense.reload
    assert_equal original_amount, @expense.amount
    assert_equal original_description, @expense.description
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy custom split update redirects without changing expense" do
    select_trip_context
    original_amount = @expense.amount

    patch trip_expense_resource_path, params: {
      expense: {
        amount: 90.0,
        description: "Updated with custom split",
        category: "food",
        expense_date: Date.current,
        currency: "EUR",
        payer_id: @user.id,
        custom_amounts: {
          @user.id.to_s => "30.0",
          @member.id.to_s => "60.0"
        }
      }
    }

    @expense.reload
    assert_equal original_amount, @expense.amount
    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy delete redirects without deleting expense" do
    select_trip_context
    assert_no_difference("Expense.count") do
      delete trip_expense_resource_path
    end

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy duplicate redirects without duplicating expense" do
    select_trip_context
    assert_no_difference("Expense.count") do
      get trip_duplicate_expense_path
    end

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy invalid create still redirects to new expense app" do
    select_trip_context
    post trip_expenses_index_path, params: {
      expense: {
        amount: nil, # Invalid
        description: "",
        category: "food",
        expense_date: Date.current,
        currency: "EUR"
      }
    }

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  test "legacy invalid update still redirects to new expense app" do
    select_trip_context
    patch trip_expense_resource_path, params: {
      expense: {
        amount: -10.0, # Invalid
        description: @expense.description,
        category: @expense.category
      }
    }

    assert_redirected_to expenses_path
    assert_equal "The new expense app now handles this flow.", flash[:notice]
  end

  # Authentication handled by test_helper
end
