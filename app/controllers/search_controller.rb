class SearchController < ApplicationController
  before_action :require_authentication

  def index
    @query = params[:query]
    if @query.present?
      # Search trips
      @trips = Current.user.trips.where("LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", "%#{@query}%", "%#{@query}%")

      # Search journal entries
      @journal_entries = JournalEntry.joins(:trip)
                                     .where(trips: { user_id: Current.user.id })
                                     .where("LOWER(journal_entries.content) LIKE LOWER(?) OR LOWER(journal_entries.location) LIKE LOWER(?)", "%#{@query}%", "%#{@query}%")
    else
      @trips = []
      @journal_entries = []
    end
  end

  def global
    query = params[:q]&.strip

    if query.blank?
      render json: { results: [] }
      return
    end

    results = []

    # Search trips (user's trips and trips they're a member of)
    trips = search_trips(query)
    results += trips.map { |trip| format_trip_result(trip) }

    # Search journal entries
    journal_entries = search_journal_entries(query)
    results += journal_entries.map { |entry| format_journal_entry_result(entry) }

    # Search recipes
    recipes = search_recipes(query)
    results += recipes.map { |recipe| format_recipe_result(recipe) }

    # Search discussions
    discussions = search_discussions(query)
    results += discussions.map { |discussion| format_discussion_result(discussion) }

    # Search expenses
    expenses = search_expenses(query)
    results += expenses.map { |expense| format_expense_result(expense) }

    # Search date proposals
    date_proposals = search_date_proposals(query)
    results += date_proposals.map { |proposal| format_date_proposal_result(proposal) }

    # Limit to 50 results total
    results = results.take(50)

    render json: { results: results }
  end

  private

  def search_trips(query)
    user_trips = Current.user.trips
    member_trips = Current.user.member_trips

    Trip.where(id: user_trips.pluck(:id) + member_trips.pluck(:id))
        .where("LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", "%#{query}%", "%#{query}%")
        .order(updated_at: :desc)
        .limit(10)
  end

  def search_journal_entries(query)
    trip_ids = Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)

    JournalEntry.where(trip_id: trip_ids)
                .where("LOWER(content) LIKE LOWER(?) OR LOWER(location) LIKE LOWER(?) OR LOWER(location_name) LIKE LOWER(?)",
                       "%#{query}%", "%#{query}%", "%#{query}%")
                .includes(:trip)
                .order(entry_date: :desc)
                .limit(10)
  end

  def search_recipes(query)
    trip_ids = Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)

    Recipe.where("(source_type = 'public') OR (source_type = 'personal' AND user_id = ?) OR (source_type = 'trip' AND trip_id IN (?))",
                 Current.user.id, trip_ids)
          .where("LOWER(name) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", "%#{query}%", "%#{query}%")
          .order(created_at: :desc)
          .limit(10)
  end

  def search_discussions(query)
    trip_ids = Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)

    DiscussionPost.where(trip_id: trip_ids)
                  .where("LOWER(title) LIKE LOWER(?) OR LOWER(content) LIKE LOWER(?)", "%#{query}%", "%#{query}%")
                  .includes(:trip)
                  .order(created_at: :desc)
                  .limit(10)
  end

  def search_expenses(query)
    trip_ids = Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)

    Expense.where(trip_id: trip_ids)
           .where("LOWER(description) LIKE LOWER(?) OR LOWER(category) LIKE LOWER(?) OR LOWER(location) LIKE LOWER(?)",
                  "%#{query}%", "%#{query}%", "%#{query}%")
           .includes(:trip)
           .order(expense_date: :desc)
           .limit(10)
  end

  def search_date_proposals(query)
    trip_ids = Current.user.trips.pluck(:id) + Current.user.member_trips.pluck(:id)

    DateProposal.where(trip_id: trip_ids)
                .where("LOWER(title) LIKE LOWER(?) OR LOWER(description) LIKE LOWER(?)", "%#{query}%", "%#{query}%")
                .includes(:trip)
                .order(created_at: :desc)
                .limit(10)
  end

  def format_trip_result(trip)
    {
      type: 'trip',
      title: trip.name,
      description: trip.description&.truncate(100),
      subtitle: "#{trip.status.titleize} • #{trip.start_date&.strftime('%b %d, %Y')}",
      badge: trip.status.titleize,
      url: trip_path(trip)
    }
  end

  def format_journal_entry_result(entry)
    {
      type: 'journal_entry',
      title: entry.location_name || entry.location || "Journal Entry",
      description: entry.content&.truncate(100),
      subtitle: "#{entry.trip.name} • #{entry.entry_date&.strftime('%b %d, %Y')}",
      badge: entry.category&.titleize,
      url: trip_journal_entry_path(entry.trip, entry)
    }
  end

  def format_recipe_result(recipe)
    source_badge = case recipe.source_type
                   when 'public' then 'Public'
                   when 'personal' then 'Personal'
                   when 'trip' then recipe.trip&.name
                   end

    {
      type: 'recipe',
      title: recipe.name,
      description: recipe.description&.truncate(100),
      subtitle: "#{recipe.servings} servings",
      badge: source_badge,
      url: recipe_path(recipe)
    }
  end

  def format_discussion_result(discussion)
    {
      type: 'discussion',
      title: discussion.title,
      description: discussion.content&.truncate(100),
      subtitle: "#{discussion.trip.name} • #{discussion.created_at.strftime('%b %d, %Y')}",
      url: trip_discussion_post_path(discussion.trip, discussion)
    }
  end

  def format_expense_result(expense)
    {
      type: 'expense',
      title: expense.description,
      description: expense.location,
      subtitle: "#{expense.trip.name} • #{number_to_currency(expense.amount)}",
      badge: expense.category&.titleize,
      url: trip_expenses_path(expense.trip)
    }
  end

  def format_date_proposal_result(proposal)
    {
      type: 'date_proposal',
      title: proposal.title || "Date Proposal",
      description: proposal.description&.truncate(100),
      subtitle: "#{proposal.trip.name} • #{proposal.start_date&.strftime('%b %d, %Y')}",
      url: trip_date_proposals_path(proposal.trip)
    }
  end
end