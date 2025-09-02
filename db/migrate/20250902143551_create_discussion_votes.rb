class CreateDiscussionVotes < ActiveRecord::Migration[8.0]
  def change
    create_table :discussion_votes do |t|
      t.references :user, null: false, foreign_key: true
      t.string :votable_type, null: false
      t.integer :votable_id, null: false
      t.string :vote_type, null: false

      t.timestamps
    end
    
    add_index :discussion_votes, [:votable_type, :votable_id]
    add_index :discussion_votes, [:user_id, :votable_type, :votable_id], unique: true, name: 'index_discussion_votes_uniqueness'
  end
end
