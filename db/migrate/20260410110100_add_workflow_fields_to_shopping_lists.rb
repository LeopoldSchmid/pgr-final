class AddWorkflowFieldsToShoppingLists < ActiveRecord::Migration[8.1]
  def change
    add_column :shopping_lists, :description, :text
    add_column :shopping_lists, :position, :integer
    add_column :shopping_lists, :archived_at, :datetime
  end
end
