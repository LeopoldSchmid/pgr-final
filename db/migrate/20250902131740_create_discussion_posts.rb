class CreateDiscussionPosts < ActiveRecord::Migration[8.0]
  def change
    create_table :discussion_posts do |t|
      t.references :trip, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :content, null: false
      t.integer :upvotes_count, default: 0, null: false
      t.integer :downvotes_count, default: 0, null: false

      t.timestamps
    end
  end
end
