class AddSelectedForShoppingToRecipes < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :selected_for_shopping, :boolean
  end
end
