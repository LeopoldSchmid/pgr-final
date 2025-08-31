class CreateDateProposalVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :date_proposal_votes do |t|
      t.references :date_proposal, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :vote_type

      t.timestamps
    end
  end
end
