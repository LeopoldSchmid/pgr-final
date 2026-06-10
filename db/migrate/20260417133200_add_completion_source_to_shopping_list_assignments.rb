class AddCompletionSourceToShoppingListAssignments < ActiveRecord::Migration[8.0]
  def change
    add_column :shopping_list_assignments, :completion_source, :string
    add_index :shopping_list_assignments, :completion_source
  end
end
