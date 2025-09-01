class AddTitleToDateProposals < ActiveRecord::Migration[8.0]
  def change
    add_column :date_proposals, :title, :string
  end
end
