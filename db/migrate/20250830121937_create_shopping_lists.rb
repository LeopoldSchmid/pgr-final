class CreateShoppingLists < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_lists do |t|
      t.references :trip, null: false, foreign_key: true
      t.string :name
      t.string :status

      t.timestamps
    end
  end
end
