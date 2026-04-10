class CreateShoppingItemComments < ActiveRecord::Migration[8.1]
  def change
    create_table :shopping_item_comments do |t|
      t.references :shopping_list_assignment, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :body, null: false
      t.datetime :resolved_at
      t.datetime :edited_at
      t.timestamps
    end
  end
end
