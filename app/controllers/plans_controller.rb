class PlansController < ApplicationController
  before_action :require_authentication
  before_action :ensure_trip_context

  def index
    @trip = current_trip

    # Load planning-related resources for the current trip
    @date_proposals = @trip.date_proposals.includes(:proposed_by, :user_availabilities).order(created_at: :desc)
    @discussions = @trip.discussions.includes(:user).order(created_at: :desc).limit(10)
    @shopping_lists = @trip.shopping_lists.order(created_at: :desc)
    @recipes = @trip.recipes.where(selected: true).order(created_at: :desc)

    # Count stats for overview
    @total_proposals = @date_proposals.count
    @total_discussions = @trip.discussions.count
    @total_shopping_items = @trip.shopping_lists.joins(:shopping_items).count
    @selected_recipes_count = @recipes.count
  end

  private

  def ensure_trip_context
    unless current_trip
      flash[:alert] = t('plans.errors.no_trip_selected')
      redirect_to select_trip_path(return_to: plans_path)
    end
  end
end
