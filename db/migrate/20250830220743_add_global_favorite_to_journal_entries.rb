class AddGlobalFavoriteToJournalEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :journal_entries, :global_favorite, :boolean
  end
end
