class CreateExpenses < ActiveRecord::Migration[8.0]
  def change
    create_table :expenses do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :payer, null: false, foreign_key: { to_table: :users }
      t.decimal :amount, precision: 10, scale: 2, null: false
      t.string :description, null: false
      t.string :category, null: false, default: 'other'
      t.date :expense_date, null: false
      t.string :currency, null: false, default: 'EUR'
      t.decimal :latitude, precision: 10, scale: 6
      t.decimal :longitude, precision: 10, scale: 6
      t.string :location

      t.timestamps
    end
    
    add_index :expenses, :category
    add_index :expenses, :expense_date
  end
end
