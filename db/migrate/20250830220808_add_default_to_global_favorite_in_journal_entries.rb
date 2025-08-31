class AddDefaultToGlobalFavoriteInJournalEntries < ActiveRecord::Migration[8.0]
  def change
    change_column_default :journal_entries, :global_favorite, from: nil, to: false
  end
end
