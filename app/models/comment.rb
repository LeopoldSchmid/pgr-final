class Comment < ApplicationRecord
  belongs_to :user
  belongs_to :journal_entry
end
