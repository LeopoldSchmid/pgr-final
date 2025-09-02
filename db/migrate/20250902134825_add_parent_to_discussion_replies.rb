class AddParentToDiscussionReplies < ActiveRecord::Migration[8.0]
  def change
    add_reference :discussion_replies, :parent, null: true, foreign_key: { to_table: :discussion_replies }
  end
end
