class CreateJournalEntries < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_entries do |t|
      t.references :trip, null: false, foreign_key: true
      t.text :content
      t.string :location
      t.boolean :favorite
      t.date :entry_date
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
