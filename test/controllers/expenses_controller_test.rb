require "test_helper"

class ExpensesControllerTest < ActionDispatch::IntegrationTest
  def setup
    @user = users(:owner)
    @member = users(:member)
    @trip = trips(:planning)
    @expense = expenses(:lunch)
    sign_in_as(@user)
  end

  test "should get index" do
    get trip_expenses_path(@trip)
    assert_response :success
    assert_includes response.body, "Trip Expenses"
    assert_includes response.body, @expense.description
  end

  test "should get by_person page" do
    session[:current_trip_id] = @trip.id
    get expenses_by_person_url
    assert_response :success
  end

  test "should get by_category page" do
    session[:current_trip_id] = @trip.id
    get expenses_by_category_url
    assert_response :success
  end

  test "should get settle page" do
    session[:current_trip_id] = @trip.id
    get expenses_settle_url
    assert_response :success
  end

  test "should get summary page" do
    get expenses_summary_url
    assert_response :success
  end

  test "should get new" do
    get new_trip_expense_path(@trip)
    assert_response :success
    assert_includes response.body, "Add New Expense"
  end

  test "should create expense with equal split" do
    assert_difference('Expense.count') do
      post trip_expenses_path(@trip), params: {
        expense: {
          amount: 50.0,
          description: "Test dinner",
          category: "food",
          expense_date: Date.current,
          currency: "EUR",
          payer_id: @user.id,
          participant_ids: [@user.id, @member.id]
        }
      }
    end

    expense = Expense.last
    assert_equal 50.0, expense.amount
    assert_equal "Test dinner", expense.description
    assert_equal @user, expense.payer
    assert_equal 2, expense.expense_participants.count
    assert_equal 25.0, expense.expense_participants.first.amount_owed

    assert_redirected_to trip_expenses_path(@trip)
    follow_redirect!
    assert_includes response.body, "Expense added successfully"
  end

  test "should create expense with custom split" do
    assert_difference('Expense.count') do
      post trip_expenses_path(@trip), params: {
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

    expense = Expense.last
    assert_equal 100.0, expense.amount
    assert_equal 2, expense.expense_participants.count

    user_participant = expense.expense_participants.find_by(user: @user)
    member_participant = expense.expense_participants.find_by(user: @member)
    
    assert_equal 60.0, user_participant.amount_owed
    assert_equal 40.0, member_participant.amount_owed

    assert_redirected_to trip_expenses_path(@trip)
  end

  test "should allow different payer than current user" do
    assert_difference('Expense.count') do
      post trip_expenses_path(@trip), params: {
        expense: {
          amount: 30.0,
          description: "Member paid",
          category: "food", 
          expense_date: Date.current,
          currency: "EUR",
          payer_id: @member.id,
          participant_ids: [@user.id, @member.id]
        }
      }
    end

    expense = Expense.last
    assert_equal @member, expense.payer
    assert_redirected_to trip_expenses_path(@trip)
  end

  test "should get edit" do
    get edit_trip_expense_path(@trip, @expense)
    assert_response :success
    assert_includes response.body, "Edit Expense"
    assert_includes response.body, @expense.description
  end

  test "should update expense" do
    patch trip_expense_path(@trip, @expense), params: {
      expense: {
        amount: 75.0,
        description: "Updated dinner",
        category: "food",
        expense_date: Date.current,
        currency: "EUR",
        payer_id: @user.id,
        participant_ids: [@user.id, @member.id]
      }
    }

    @expense.reload
    assert_equal 75.0, @expense.amount
    assert_equal "Updated dinner", @expense.description
    assert_redirected_to trip_expenses_path(@trip)
    follow_redirect!
    assert_includes response.body, "Expense updated successfully"
  end

  test "should update expense with custom split" do
    patch trip_expense_path(@trip, @expense), params: {
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
    assert_equal 90.0, @expense.amount
    
    user_participant = @expense.expense_participants.find_by(user: @user)
    member_participant = @expense.expense_participants.find_by(user: @member)
    
    assert_equal 30.0, user_participant.amount_owed
    assert_equal 60.0, member_participant.amount_owed
    assert_redirected_to trip_expenses_path(@trip)
  end

  test "should delete expense" do
    assert_difference('Expense.count', -1) do
      delete trip_expense_path(@trip, @expense)
    end

    assert_redirected_to trip_expenses_path(@trip)
    follow_redirect!
    assert_includes response.body, "Expense deleted successfully"
  end

  test "should duplicate expense" do
    assert_difference('Expense.count', 1) do
      get duplicate_trip_expense_path(@trip, @expense)
    end

    duplicated = Expense.last
    assert_equal @expense.description + " (copy)", duplicated.description
    assert_equal @expense.amount, duplicated.amount
    assert_equal @expense.category, duplicated.category
    assert_equal Date.current, duplicated.expense_date

    assert_redirected_to trip_expenses_path(@trip)
    follow_redirect!
    assert_includes response.body, "Expense duplicated successfully"
  end

  test "should handle validation errors on create" do
    post trip_expenses_path(@trip), params: {
      expense: {
        amount: nil, # Invalid
        description: "",
        category: "food",
        expense_date: Date.current,
        currency: "EUR"
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Add New Expense" # Should render new template
  end

  test "should handle validation errors on update" do
    patch trip_expense_path(@trip, @expense), params: {
      expense: {
        amount: -10.0, # Invalid
        description: @expense.description,
        category: @expense.category
      }
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "Edit Expense" # Should render edit template
  end

  # Authentication handled by test_helper
end