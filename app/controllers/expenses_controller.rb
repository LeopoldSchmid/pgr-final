class ExpensesController < ApplicationController
  before_action :require_authentication
  before_action :set_trip
  before_action :set_expense, only: [:show, :edit, :update, :destroy, :duplicate]
  before_action :check_expense_permissions, only: [:create, :edit, :update, :destroy]
  
  def index
    @expenses = @trip.expenses.includes(:payer, :participants).recent
    @total_expenses = @trip.total_expenses
    @expenses_by_category = @trip.expenses_by_category
    @user_balance = @trip.user_balance(Current.user)
    @settlement_suggestions = @trip.settlement_suggestions
  end

  def new
    @expense = @trip.expenses.build(
      payer: Current.user,
      expense_date: Date.current,
      currency: 'EUR'
    )
    @trip_members = [@trip.user] + @trip.active_members
  end

  def create
    @expense = @trip.expenses.build(expense_params.merge(payer: Current.user))
    
    if @expense.save
      # Split expense among selected participants
      participant_ids = params[:expense][:participant_ids]&.reject(&:blank?)
      if participant_ids.present?
        participants = User.where(id: participant_ids)
        @expense.split_equally_among(participants)
      else
        # Default: split among all active trip members
        all_members = [@trip.user] + @trip.active_members
        @expense.split_equally_among(all_members)
      end
      
      redirect_to trip_expenses_path(@trip), notice: '💰 Expense added successfully!'
    else
      @trip_members = [@trip.user] + @trip.active_members
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @trip_members = [@trip.user] + @trip.active_members
    @selected_participant_ids = @expense.participants.pluck(:id)
  end

  def update
    if @expense.update(expense_params)
      # Update participants if provided
      participant_ids = params[:expense][:participant_ids]&.reject(&:blank?)
      if participant_ids.present?
        participants = User.where(id: participant_ids)
        @expense.split_equally_among(participants)
      end
      
      redirect_to trip_expenses_path(@trip), notice: '💰 Expense updated successfully!'
    else
      @trip_members = [@trip.user] + @trip.active_members
      @selected_participant_ids = @expense.participants.pluck(:id)
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to trip_expenses_path(@trip), notice: '🗑️ Expense deleted successfully!'
  end

  def duplicate
    @new_expense = @expense.dup
    @new_expense.expense_date = Date.current
    @new_expense.description = "#{@expense.description} (copy)"
    
    if @new_expense.save
      # Copy participants
      @expense.expense_participants.each do |participant|
        @new_expense.expense_participants.create!(
          user: participant.user,
          amount_owed: participant.amount_owed
        )
      end
      
      redirect_to trip_expenses_path(@trip), notice: '📋 Expense duplicated successfully!'
    else
      redirect_to trip_expenses_path(@trip), alert: 'Failed to duplicate expense.'
    end
  end

  private

  def set_trip
    @trip = Current.user.all_trips.find(params[:trip_id])
  end

  def set_expense
    @expense = @trip.expenses.find(params[:id])
  end

  def check_expense_permissions
    unless @trip.user_can_manage_expenses?(Current.user)
      redirect_to @trip, alert: 'You do not have permission to manage expenses for this trip.'
    end
  end

  def expense_params
    params.require(:expense).permit(
      :amount, :description, :category, :expense_date, :currency, :receipt
    )
  end
end
