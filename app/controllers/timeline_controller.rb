class TimelineController < ApplicationController
  before_action :require_authentication

  def index
    @journal_entries = JournalEntry.where(user: Current.user).order(entry_date: :desc, created_at: :desc)
  end
end
