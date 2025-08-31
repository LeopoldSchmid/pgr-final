class AddDiscussionFieldsToDateProposals < ActiveRecord::Migration[8.0]
  def change
    add_column :date_proposals, :description, :text
    add_column :date_proposals, :notes, :text
  end
end
