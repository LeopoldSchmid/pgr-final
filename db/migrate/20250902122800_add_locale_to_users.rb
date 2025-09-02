class AddLocaleToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :locale, :string, default: 'en', null: false
    add_index :users, :locale
  end
end
