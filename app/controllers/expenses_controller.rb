class ExpensesController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context
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

  # Secondary nav: By Person
  def by_person
    @expenses = @trip.expenses.includes(:payer, :participants).recent
    @expenses_by_person = @expenses.group_by(&:payer)
    @total_by_person = @expenses_by_person.transform_values { |exps| exps.sum(&:amount) }
  end

  # Secondary nav: By Category
  def by_category
    @expenses = @trip.expenses.includes(:payer, :participants).recent
    @expenses_by_category = @trip.expenses_by_category
  end

  # Secondary nav: Settle Up
  def settle
    @user_balance = @trip.user_balance(Current.user)
    @settlement_suggestions = @trip.settlement_suggestions
    @all_balances = @trip.all_user_balances
  end

  # Global context: Summary across trips
  def summary
    # Show expense summary across all user trips
    user_trip_ids = (Current.user.trips.pluck(:id) +
                    Trip.joins(:trip_members).where(trip_members: { user: Current.user }).pluck(:id)).uniq

    @total_spent = Expense.where(trip_id: user_trip_ids).sum(:amount)
    @expenses_by_trip = Expense.where(trip_id: user_trip_ids)
                               .joins(:trip)
                               .group('trips.name')
                               .sum(:amount)
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
    payer = if expense_params[:payer_id].present?
              User.find(expense_params[:payer_id])
            else
              Current.user
            end
    @expense = @trip.expenses.build(expense_params.merge(payer: payer))
    
    if @expense.save
      # Handle expense splitting
      custom_amounts = params[:expense][:custom_amounts]
      has_custom_amounts = custom_amounts.present? && custom_amounts.values.any? { |v| v.to_f > 0 }
      
      success = if has_custom_amounts
        # Custom split amounts (only if there are actual custom amounts > 0)
        handle_custom_split(@expense, custom_amounts)
      else
        # Equal split among selected participants
        participant_ids = params[:expense][:participant_ids]&.reject(&:blank?)
        if participant_ids.present?
          participants = User.where(id: participant_ids)
          @expense.split_equally_among(participants)
        else
          # Default: split among all active trip members
          all_members = [@trip.user] + @trip.active_members
          @expense.split_equally_among(all_members)
        end
        true
      end
      
      if success
        redirect_to expenses_path, notice: '💰 Expense added successfully!'
      else
        @trip_members = [@trip.user] + @trip.active_members
        render :new, status: :unprocessable_entity
      end
    else
      @trip_members = [@trip.user] + @trip.active_members
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @trip_members = [@trip.user] + @trip.active_members
    @selected_participant_ids = @expense.participants.pluck(:id)
    set_split_type
  end

  def update
    if @expense.update(expense_params)
      # Handle expense splitting
      custom_amounts = params[:expense][:custom_amounts]
      has_custom_amounts = custom_amounts.present? && custom_amounts.values.any? { |v| v.to_f > 0 }
      
      success = if has_custom_amounts
        # Custom split amounts (only if there are actual custom amounts > 0)
        handle_custom_split(@expense, custom_amounts)
      else
        # Equal split among selected participants
        participant_ids = params[:expense][:participant_ids]&.reject(&:blank?)
        if participant_ids.present?
          # Clear existing participants first
          @expense.expense_participants.destroy_all
          
          participants = User.where(id: participant_ids)
          @expense.split_equally_among(participants)
        else
          # If no participants selected, keep existing participants
          Rails.logger.warn "No participant IDs provided for equal split, keeping existing participants"
        end
        true
      end
      
      if success
        redirect_to expenses_path, notice: '💰 Expense updated successfully!'
      else
        @trip_members = [@trip.user] + @trip.active_members
        @selected_participant_ids = @expense.participants.pluck(:id)
        set_split_type
        render :edit, status: :unprocessable_entity
      end
    else
      @trip_members = [@trip.user] + @trip.active_members
      @selected_participant_ids = @expense.participants.pluck(:id)
      set_split_type
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @expense.destroy
    redirect_to expenses_path, notice: '🗑️ Expense deleted successfully!'
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
      
      redirect_to expenses_path, notice: '📋 Expense duplicated successfully!'
    else
      redirect_to expenses_path, alert: 'Failed to duplicate expense.'
    end
  end

  private

  def ensure_trip_context
    unless current_trip
      flash[:alert] = 'Please select a trip first.'
      redirect_to select_trip_path(return_to: expenses_path)
    end
  end

  def set_trip
    @trip = current_trip
  end
  
  def set_split_type
    # Default to equal split for simplicity - user can change via radio buttons
    @is_equal_split = true
    
    # Only set to custom if we have clear evidence of custom amounts
    participants = @expense.expense_participants
    if participants.any? && participants.count > 1
      amounts = participants.map(&:amount_owed).uniq
      # If there are different amounts, it's definitely custom
      @is_equal_split = amounts.count == 1
    end
  end

  def set_expense
    @expense = @trip.expenses.find(params[:id])
  end

  def check_expense_permissions
    unless @trip.user_can_manage_expenses?(Current.user)
      redirect_to @trip, alert: 'You do not have permission to manage expenses for this trip.'
    end
  end

  def handle_custom_split(expense, custom_amounts)
    # Clear existing participants first
    expense.expense_participants.destroy_all
    
    # Filter out participants with zero amounts (unchecked or set to 0)
    # Convert ActionController::Parameters to hash if needed
    amounts_hash = custom_amounts.respond_to?(:to_unsafe_h) ? custom_amounts.to_unsafe_h : custom_amounts.to_h
    active_amounts = amounts_hash.select { |user_id, amount_str| amount_str.to_f > 0 }
    
    # Validate custom amounts add up to total
    total_assigned = active_amounts.values.map(&:to_f).sum
    if (expense.amount - total_assigned).abs >= 0.01
      expense.errors.add(:base, "Custom split amounts must equal the total expense amount (#{expense.amount} EUR). Currently assigned: #{total_assigned} EUR")
      return false
    end
    
    # Create participants with custom amounts (only for amounts > 0)
    active_amounts.each do |user_id, amount_str|
      amount = amount_str.to_f
      user = User.find(user_id)
      expense.expense_participants.create!(user: user, amount_owed: amount)
    end
    
    true
  end

  def expense_params
    params.require(:expense).permit(
      :amount, :description, :category, :expense_date, :currency, :receipt, :payer_id
    )
  end
end
