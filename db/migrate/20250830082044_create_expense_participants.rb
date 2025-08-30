class CreateExpenseParticipants < ActiveRecord::Migration[8.0]
  def change
    create_table :expense_participants do |t|
      t.references :expense, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :amount_owed, precision: 10, scale: 2, null: false

      t.timestamps
    end
    
    add_index :expense_participants, [:expense_id, :user_id], unique: true
  end
end
