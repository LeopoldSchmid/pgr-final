class CreateDiscussionReplies < ActiveRecord::Migration[8.0]
  def change
    create_table :discussion_replies do |t|
      t.references :discussion_post, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.text :content, null: false
      t.integer :upvotes_count, default: 0, null: false
      t.integer :downvotes_count, default: 0, null: false

      t.timestamps
    end
  end
end
