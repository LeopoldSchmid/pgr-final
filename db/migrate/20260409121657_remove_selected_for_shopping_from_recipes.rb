class RemoveSelectedForShoppingFromRecipes < ActiveRecord::Migration[8.1]
  def change
    remove_column :recipes, :selected_for_shopping, :boolean
  end
end
