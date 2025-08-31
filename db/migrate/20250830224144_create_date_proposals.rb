class CreateDateProposals < ActiveRecord::Migration[8.0]
  def change
    create_table :date_proposals do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
  end
end
