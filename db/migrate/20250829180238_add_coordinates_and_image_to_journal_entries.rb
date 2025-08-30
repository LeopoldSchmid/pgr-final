class AddCoordinatesAndImageToJournalEntries < ActiveRecord::Migration[8.0]
  def change
    add_column :journal_entries, :latitude, :decimal, precision: 10, scale: 6
    add_column :journal_entries, :longitude, :decimal, precision: 10, scale: 6
  end
end
