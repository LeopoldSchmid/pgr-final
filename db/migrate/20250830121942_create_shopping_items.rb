class CreateShoppingItems < ActiveRecord::Migration[8.0]
  def change
    create_table :shopping_items do |t|
      t.references :shopping_list, null: false, foreign_key: true
      t.string :name
      t.decimal :quantity
      t.string :unit
      t.string :category
      t.boolean :purchased
      t.string :source_type
      t.integer :source_id

      t.timestamps
    end
  end
end
