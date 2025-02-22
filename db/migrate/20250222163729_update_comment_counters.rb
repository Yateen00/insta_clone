class UpdateCommentCounters < ActiveRecord::Migration[8.0]
  def up
    Post.find_each { |post| Post.reset_counters(post.id, :comments) }
    Comment.find_each { |comment| Comment.reset_counters(comment.id, :replies) }
  end

  def down
    # No need to roll back counter updates
  end
end
