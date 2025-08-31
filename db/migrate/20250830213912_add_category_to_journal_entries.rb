class AddCategoryToJournalEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :journal_entries, :category, :string
  end
end
