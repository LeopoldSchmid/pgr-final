class AddRecipeHierarchyFields < ActiveRecord::Migration[8.0]
  def change
    add_column :recipes, :source_type, :string, default: 'trip'
    add_column :recipes, :parent_recipe_id, :integer
    add_column :recipes, :user_id, :integer
    add_column :recipes, :proposed_for_public, :boolean, default: false
    
    add_foreign_key :recipes, :recipes, column: :parent_recipe_id
    add_foreign_key :recipes, :users, column: :user_id
    add_index :recipes, :source_type
    add_index :recipes, :user_id
  end
end
