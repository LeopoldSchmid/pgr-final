class CreateShoppingSyncRuns < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_sync_runs do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.string :undo_token, null: false
      t.text :change_summary
      t.json :snapshot_payload
      t.timestamps
    end

    add_index :shopping_sync_runs, :undo_token, unique: true
  end
end
